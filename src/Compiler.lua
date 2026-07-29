--- [ Imports ] ----------------------------------------------------------------
local bit32 = require "bit32"
local OPCODES = require "OpCodes"
local SysCalls = require "SysCalls"

--- [ Utility ] ----------------------------------------------------------------
local function errorf(fmt, ...) error(string.format(fmt, ...), 0) end

--- [ Initialization ] ---------------------------------------------------------
local Compiler = {}
Compiler.__index = Compiler

function Compiler.new(ast)
    local self = setmetatable({
        current = 1,
        ast = ast,
        globalc = 0,
        globals = {},
        scopes = {},
        const_pool = {},
        const_map = {},
        func_table = {},
        bytecode = {},
    }, Compiler)
    return self
end

--- [ Helpers ] ----------------------------------------------------------------
function Compiler:emit8(value)
    table.insert(self.bytecode, value)
end
function Compiler:emit16(value)
    local hi, lo = bit32.band(math.floor(value / 256), 0xFF00), value % 256
    self:emit8(hi)
    self:emit8(lo)
end
function Compiler:patch16(position, value)
    local hi, lo = bit32.band(math.floor(value / 256), 0xFF00), value % 256
    self.bytecode[position] = hi
    self.bytecode[position + 1] = lo
end
function Compiler:emit_const(value)
    if self.const_map[value] then
        self:emit8(self.const_map[value])
        return
    end
    table.insert(self.const_pool, value)
    local index = #self.const_pool - 1
    self.const_map[value] = index
    self:emit8(index)
end

function Compiler:push_scope()
    table.insert(self.scopes, {})
end
function Compiler:pop_scope()
    table.remove(self.scopes)
end
function Compiler:declare_local(name)
    local scope = self.scopes[#self.scopes]
    local index = #scope
    table.insert(scope, name)
    return index
end
function Compiler:resolve_local(name)
    for i = #self.scopes, 1, -1 do
        local scope = self.scopes[i]
        for j, var_name in ipairs(scope) do
            if var_name == name then
                return j - 1
            end
        end
    end
    return nil
end
function Compiler:resolve_global(name)
    for g_name, index in pairs(self.globals) do
        if g_name == name then
            return index
        end
    end
    self.globals[name] = self.globalc
    self.globalc = self.globalc + 1
    return self.globalc - 1
end

--- [ Compiling ] --------------------------------------------------------------
function Compiler:compile_expr(node)
    if node.type == "LiteralExpr" then
        if node.value == nil then
            self:emit_const(OPCODES.NULL)
            return
        end
        self:emit8(OPCODES.CONSTANT) self:emit_const(node.value)
    elseif node.type == "AssignExpr" then
        self:compile_expr(node.value)
        local index = self:resolve_local(node.name)
        if index ~= nil then
            self:emit8(OPCODES.SET_LOCAL)
            self:emit8(index)
        else
            index = self:resolve_global(node.name)
            self:emit8(OPCODES.SET_GLOBAL)
            self:emit8(index)
        end
    elseif node.type == "VariableExpr" then
        local index = self:resolve_local(node.name)
        if index ~= nil then
            self:emit8(OPCODES.GET_LOCAL)
            self:emit8(index)
        else
            index = self:resolve_global(node.name)
            self:emit8(OPCODES.GET_GLOBAL)
            self:emit8(index)
        end
    elseif node.type == "UnaryExpr" then
        self:compile_expr(node.right)
        local operator = node.op
        if operator == "-" then self:emit8(OPCODES.NEGATE)
        elseif operator == "!" then self:emit8(OPCODES.NOT)
        else errorf("Unsupported unary operator: %s", operator)
        end
    elseif node.type == "BinaryExpr" then
        self:compile_expr(node.left)
        self:compile_expr(node.right)
        local operator = node.op
        if operator == "+" then self:emit8(OPCODES.ADD)
        elseif operator == "-" then self:emit8(OPCODES.SUB)
        elseif operator == "*" then self:emit8(OPCODES.MUL)
        elseif operator == "/" then self:emit8(OPCODES.DIV)
        elseif operator == "%" then self:emit8(OPCODES.MOD)
        elseif operator == "<<" then self:emit8(OPCODES.LSHIFT)
        elseif operator == ">>" then self:emit8(OPCODES.RSHIFT)
        elseif operator == "&" then self:emit8(OPCODES.AND)
        elseif operator == "|" then self:emit8(OPCODES.OR)
        elseif operator == "^" then self:emit8(OPCODES.XOR)
        elseif operator == "==" then self:emit8(OPCODES.EQUAL)
        elseif operator == ">" then self:emit8(OPCODES.GREATER)
        elseif operator == ">=" then self:emit8(OPCODES.LESS) self:emit8(OPCODES.NOT)
        elseif operator == "<" then self:emit8(OPCODES.LESS)
        elseif operator == "<=" then self:emit8(OPCODES.GREATER) self:emit8(OPCODES.NOT)
        else errorf("Unsupported binary operator: %s", operator)
        end
    elseif node.type == "CallExpr" then
        for _, arg in ipairs(node.args) do
            self:compile_expr(arg)
        end
        if node.callee.type ~= "VariableExpr" then
            errorf("Unsupported callee") --- TODO: Better error message
        end
        local target_name = node.callee.name

        local syscall = SysCalls.calls[target_name]
        if syscall then
            if syscall.argc and #node.args ~= syscall.argc then
                errorf("%s expects %d argument(s), got %d", target_name, syscall.argc, #node.args)
            end
            self:emit8(OPCODES.SYSCALL)
            self:emit8(syscall.id)
            return
        end

        local func_id = nil
        for id, func in ipairs(self.func_table) do
            if func.name == target_name then
                func_id = id - 1
                break
            end
        end
        if func_id == nil then
            errorf("Unknown function call: %s", target_name)
        end
        self:emit8(OPCODES.CALL)
        self:emit8(func_id)
    end
end
function Compiler:compile_stmt(node)
    if node.type == "ReturnStmt" then
        if node.value then
            self:compile_expr(node.value)
        else
            self:emit8(OPCODES.NULL)
        end
        self:emit8(OPCODES.RETURN)
    elseif node.type == "IfStmt" then
        self:compile_expr(node.cond)
        self:emit8(OPCODES.JZ)
        local jz_pos = #self.bytecode + 1
        self:emit16(0)
        self:compile_stmt(node["then"])
        
        if node["else"] then
            self:emit8(OPCODES.JMP)
            local jmp_pos = #self.bytecode + 1
            self:emit16(0)
            local then_offset = #self.bytecode - jz_pos + 1
            self:patch16(jz_pos, then_offset)
            self:compile_stmt(node["else"])
            local else_offset = #self.bytecode - jmp_pos + 1
            self:patch16(jmp_pos, else_offset)
        else
            local offset = #self.bytecode - jz_pos - 1
            self:patch16(jz_pos, offset)
        end
    elseif node.type == "WhileStmt" then
        local loop_start = #self.bytecode
        self:compile_expr(node.cond)
        self:emit8(OPCODES.JZ)
        local jz_pos = #self.bytecode + 1
        self:emit16(0)

        self:compile_stmt(node.body)

        local loop_offset = #self.bytecode - loop_start + 3
        self:emit8(OPCODES.LOOP)
        self:emit16(loop_offset)
        local loop_end = #self.bytecode - jz_pos + 1
        self:patch16(jz_pos, loop_end)
    elseif node.type == "VarStmt" then
        if node.init then
            self:compile_expr(node.init)
        else
            self:emit8(OPCODES.NULL)
        end
        local index = self:declare_local(node.name)
        self:emit8(OPCODES.SET_LOCAL)
        self:emit8(index)
    elseif node.type == "BlockStmt" then
        for _, stmt in ipairs(node.body) do
            self:compile_stmt(stmt)
        end
    elseif node.type == "ExprStmt" then
        self:compile_expr(node.expr)
    end
end
function Compiler:compile()
    local main_func
    local funcs = {}
    for _, stmt in ipairs(self.ast.statements) do
        if stmt.type == "FuncDecl" then
            if stmt.name == "main" then
                main_func = stmt
            else
                table.insert(funcs, stmt)
            end
        else
            errorf("Invalid top level code") --- TODO: Better Error Messages
        end
    end
    for _, func_stmt in ipairs(funcs) do
        table.insert(self.func_table, { name = func_stmt.name, argc = #func_stmt.params, address = 0 })
    end
    if not main_func then
        errorf("Compilation error: Missing 'main' entry point.")
    end
    self:push_scope()
    self:compile_stmt(main_func.body)
    if self.bytecode[#self.bytecode] == OPCODES.RETURN then
        self.bytecode[#self.bytecode] = OPCODES.SYSCALL self:emit8(0x06)
    end
    self:emit8(OPCODES.HALT)
    self:pop_scope()

    for i, func_stmt in ipairs(funcs) do
        self.func_table[i].address = #self.bytecode
        self:push_scope()
        for _, param in ipairs(func_stmt.params) do
            self:declare_local(param)
        end
        self:compile_stmt(func_stmt.body)
        if self.bytecode[#self.bytecode] ~= OPCODES.RETURN then
            self:emit8(OPCODES.NULL)
            self:emit8(OPCODES.RETURN)
        end
        self:pop_scope()
    end

    return {
        const_pool = self.const_pool,
        func_table = self.func_table,
        bytecode = self.bytecode,
    }
end

return Compiler