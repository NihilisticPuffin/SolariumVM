--- [ bit32 Lib ] --------------------------------------------------------------
local bit32 = bit32 or {
    bor = load("return function(a, b) return a | b end")(),
    band = load("return function(a, b) return a & b end")(),
    bxor = load("return function(a, b) return a ~ b end")(),
    bnot = load("return function(a) return ~a end")(),
    lshift = load("return function(a, b) return a << b end")(),
    rshift = load("return function(a, b) return a >> b end")(),
}

--- [ Imports ] ----------------------------------------------------------------
local OPCODES = require "OpCodes"

--- [ Helpers ] ----------------------------------------------------------------
local function bool(v) return v and 1 or 0 end
local NULL = setmetatable({}, { __tostring = function() return "null" end })
local function errorf(fmt, ...) error(string.format(fmt, ...), 0) end

--- [ Stack ] ------------------------------------------------------------------
local Stack = {}
Stack.__index = Stack
function Stack.new()
    local self = {
        _data = {}
    }
    return setmetatable(self, Stack)
end

function Stack:push(value)
    table.insert(self._data, value)
end
function Stack:pop()
    if self:isEmpty() then
        return nil, "Stack underflow"
    end
    return table.remove(self._data)
end
function Stack:peek(offset)
    local offset = offset or 0
    if self:isEmpty() then
        return nil, "Stack is empty"
    end
    return self._data[#self._data - offset]
end
function Stack:clear()
    self._data = {}
end
function Stack:isEmpty()
    return #self._data == 0
end
function Stack:size()
    return #self._data
end

--- [ Sys Calls ] --------------------------------------------------------------
local SYSCALLS = {
    [0x00] = function(vm) --- SYS_PRINT
        print(vm.stack:pop())
    end,
    [0x01] = function(vm) --- SYS_OPEN
        local modes = { "r", "w", "a" }
        local mode = vm.stack:pop()
        local fh = io.open(vm.stack:pop(), modes[bit32.band(mode, 0x0F)] .. ((bit32.band(mode, 0x10) == 1) and '+' or ''))
        vm.stack:push(fh)
    end,
    [0x02] = function(vm) --- SYS_READ
        local fh = vm.stack:pop()
        vm.stack:push(fh:read("*a"))
    end,
    [0x03] = function(vm) --- SYS_CLOSE
        local fh = vm.stack:pop()
        fh:close()
    end,
    [0x04] = function(vm) --- SYS_TIME
        vm.stack:push(os.epoch("utc"))
    end,
}

--- [ Initialization ] ---------------------------------------------------------
local VM = {}
VM.__index = VM

function VM.new()
    local self = setmetatable({
        --- [ Execution ]
        ip = 0,
        bytecode = {},
        running = false,

        --- [ Memory & Storage ]
        stack = Stack.new(),
        globals = {},
        const_pool = {},

        --- [ Subroutines & Call Stack ]
        func_table = {},
        frames = Stack.new(),

        --- [ Syscalls ]
        syscalls = SYSCALLS
    }, VM)
    return self
end

function VM:reset()
    self.ip = 0
    self.bytecode = {}
    self.running = false
    self.stack:clear()
    self.globals = {}
    self.const_pool = {}
    self.func_table = {}
    self.frames:clear()

    return self
end

function VM:load(data)
    if type(data.bytecode) == "table" then
        self.bytecode = data.bytecode
    else
        self.bytecode = { string.byte(data.bytecode, 1, #data.bytecode) }
    end
    self.const_pool = data.const_pool or {}
    self.func_table = data.func_table or {}
    return self
end

--- [ Bytecode Reading ] -------------------------------------------------------
function VM:read8()
    local byte = self.bytecode[self.ip + 1]
    self.ip = self.ip + 1
    return byte
end
function VM:read16()
    local hi = self:read8()
    local lo = self:read8()
    return bit32.bor(bit32.lshift(hi, 8), lo)
end

--- [ Opcode Handlers ] --------------------------------------------------------
local BINARY_HANDLERS = {
    [OPCODES.ADD]     = function(a, b) return a + b end,
    [OPCODES.SUB]     = function(a, b) return a - b end,
    [OPCODES.MUL]     = function(a, b) return a * b end,
    [OPCODES.DIV]     = function(a, b) return a / b end,
    [OPCODES.MOD]     = function(a, b) return a % b end,
    [OPCODES.POW]     = function(a, b) return a ^ b end,
    [OPCODES.LSHIFT]  = function(a, b) return bit32.lshift(a, b) end,
    [OPCODES.RSHIFT]  = function(a, b) return bit32.rshift(a, b) end,
    [OPCODES.AND]     = function(a, b) return bit32.band(a, b) end,
    [OPCODES.OR]      = function(a, b) return bit32.bor(a, b) end,
    [OPCODES.XOR]     = function(a, b) return bit32.bxor(a, b) end,
    [OPCODES.EQUAL]   = function(a, b) return bool(a == b) end,
    [OPCODES.GREATER] = function(a, b) return bool(a > b) end,
    [OPCODES.LESS]    = function(a, b) return bool(a < b) end,
}

local handlers = {}
handlers[OPCODES.NOP] = function(self) end
handlers[OPCODES.CONSTANT] = function(self)
    local id = self:read8()
    local const_index = id + 1
    if not self.const_pool[const_index] then
        errorf("Invalid constant pool ID: %d at IP: %d", id, self.ip - 1)
    end
    self.stack:push(self.const_pool[const_index])
end
handlers[OPCODES.NULL] = function(self) self.stack:push(NULL) end
handlers[OPCODES.POP] = function(self) self.stack:pop() end
handlers[OPCODES.DUP] = function(self) self.stack:push(self.stack:peek()) end
handlers[OPCODES.SWAP] = function(self)
    local b, a = self.stack:pop(), self.stack:pop()
    self.stack:push(b)
    self.stack:push(a)
end

handlers[OPCODES.GET_GLOBAL] = function(self)
    local index = self:read8()
    if self.globals[index] == nil then
        errorf("Unknown global index: %d at IP: %d", index, self.ip - 1)
    end
    self.stack:push(self.globals[index])
end

handlers[OPCODES.SET_GLOBAL] = function(self)
    self.globals[self:read8()] = self.stack:pop()
end

handlers[OPCODES.GET_LOCAL] = function(self)
    local index = self:read8()
    local frame = self.frames:peek()
    if not frame then
        errorf("No active call frame for GET_LOCAL at IP: %d", self.ip - 2)
    end
    local offset = frame.base_pointer + index + 1
    if offset <= frame.base_pointer or offset > self.stack:size() then
        errorf("Local index out of bounds: %d (offset %d) at IP: %d", index, offset, self.ip - 2)
    end

    self.stack:push(self.stack._data[offset])
end
handlers[OPCODES.SET_LOCAL] = function(self)
    local index = self:read8()
    local frame = self.frames:peek()
    if not frame then
        errorf("No active call frame for GET_LOCAL at IP: %d", self.ip - 2)
    end
    local offset = frame.base_pointer + index + 1
    if offset <= frame.base_pointer or offset > self.stack:size() then
        errorf("Local index out of bounds: %d (offset %d) at IP: %d", index, offset, self.ip - 2)
    end

    self.stack._data[offset] = self.stack:pop()
end

handlers[OPCODES.INC] = function(self)
    local value = self.stack:pop()
    self.stack:push(value + 1)
end
handlers[OPCODES.DEC] = function(self)
    local value = self.stack:pop()
    self.stack:push(value - 1)
end
handlers[OPCODES.NEGATE] = function(self)
    local value = self.stack:pop()
    self.stack:push(-value)
end

handlers[OPCODES.NOT] = function(self)
    local value = self.stack:pop()
    self.stack:push(bool(value == 0 or value == nil or value == NULL))
end

handlers[OPCODES.JMP] = function(self)
    local offset = self:read16()
    self.ip = self.ip + offset
end
handlers[OPCODES.JNZ] = function(self)
    local offset = self:read16()
    local condition = self.stack:pop()
    
    if condition ~= nil and condition ~= 0 and condition ~= NULL then
        self.ip = self.ip + offset
    end
end
handlers[OPCODES.LOOP] = function(self)
    local offset = self:read16()
    self.ip = self.ip - offset
end

handlers[OPCODES.CALL] = function(self)
    local func_id = self:read8()
    local func = self.func_table[func_id + 1]
    
    if not func then
        errorf("Function not found for ID: %d at IP: %d", func_id, self.ip - 2)
    end
    
    local base_pointer = self.stack:size() - func.argc

    self.frames:push({ return_ip = self.ip, base_pointer = base_pointer, func_id = func_id })
    self.ip = func.address
end
handlers[OPCODES.RETURN] = function(self)
    local value = self.stack:pop()
    local frame = self.frames:pop()

    if frame == nil then
        self.running = false
        return
    end

    while self.stack:size() > frame.base_pointer do self.stack:pop() end
    self.stack:push(value)
    self.ip = frame.return_ip
end

handlers[OPCODES.SYSCALL] = function(self)
    local sys_id = self:read8()
    local sys_handler = self.syscalls[sys_id]
    if not sys_handler then
        errorf("Unknown or unhandled syscall ID: 0x%02X at IP: %d", sys_id, self.ip - 1)
    end
    sys_handler(self)
end

handlers[OPCODES.HALT] = function(self) self.running = false end

for opcode, handler in pairs(BINARY_HANDLERS) do
    handlers[opcode] = function(self)
        local b, a = self.stack:pop(), self.stack:pop()
        self.stack:push(handler(a, b))
    end
end

--- [ Execution ] --------------------------------------------------------------
function VM:step()
    if self.ip >= #self.bytecode then
        self.running = false
        return
    end

    local op = self:read8()
    local handler = handlers[op]
    
    if handler then
        handler(self)
    else
        errorf("Unknown opcode: 0x%02X at IP: %d", op, self.ip - 1)
    end
end

function VM:run()
    self.running = true
    while self.running do self:step() end
    return self
end

return VM