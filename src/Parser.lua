local function get_source_line(source, target_line)
    local current_line = 1
    for line in source:gmatch("([^\r\n]*)\r?\n?") do
        if current_line == target_line then
            return line
        end
        current_line = current_line + 1
    end
    return ""
end

local TT = require "TokenTypes"
local AST = require "Nodes"

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens, source, file)
    local self = setmetatable({
        tokens = tokens,
        current = 1,
        source = source or "",
        file = file,
    }, Parser)
    return self
end

function Parser:error(code, message, token, note)
    token = token or self:peek()
    local line   = token.line or 1
    local column = token.column or 1
    local length = #(token.lexeme or "")
    if length == 0 then length = 1 end

    local line_text  = get_source_line(self.source, line)
    local line_label = tostring(line)
    local gutter     = string.rep(' ', #line_label)

    local out = {}
    table.insert(out, string.format("error[%s]: %s", code, message))
    table.insert(out, string.format("%s --> %s:%d:%d", gutter, self.file, line, column))
    table.insert(out, gutter .. " |")
    table.insert(out, string.format("%s | %s", line_label, line_text))
    table.insert(out, gutter .. " | " .. string.rep(' ', math.max(0, column - 1)) .. string.rep('^', length))

    if note then
        table.insert(out, gutter .. " |")
        table.insert(out, gutter .. " = " .. note)
    else
        table.insert(out, gutter .. " |")
    end

    io.stderr:write(table.concat(out, "\n") .. "\n")
    error()
end

function Parser:at_end()
    return self:peek().type == TT.EOF
end

function Parser:peek(offset)
    offset = offset or 0
    local idx = self.current + offset
    if idx > #self.tokens then return self.tokens[#self.tokens] end
    return self.tokens[idx]
end

function Parser:advance()
    local previous = self:peek()
    if not self:at_end() then
        self.current = self.current + 1
    end
    return previous
end

function Parser:check(type)
    if self:at_end() then return false end
    return self:peek().type == type
end

function Parser:match(...)
    local types = {...}
    for _, type in ipairs(types) do
        if self:check(type) then
            self:advance()
            return true
        end
    end
    return false
end

function Parser:consume(type, code, message, note)
    if self:check(type) then return self:advance() end
    self:error(code, message, self:peek(), note)
end


function Parser:parse()
    local statements = {}
    while not self:at_end() do
        table.insert(statements, self:declaration())
    end
    return AST.Program(statements)
end

function Parser:declaration()
    if self:match(TT.FUNC) then
        return self:func_declaration()
    end
    return self:statement()
end

function Parser:func_declaration()
    local name = self:consume(TT.IDENTIFIER, "P003", "Expected function name after 'fn'.").lexeme
    self:consume(TT.LPAREN, "P004", "Expected '(' after function name.")

    local params = {}
    if not self:check(TT.RPAREN) then
        repeat
            table.insert(params, self:consume(TT.IDENTIFIER, "P005", "Expected parameter name.").lexeme)
        until not self:match(TT.COMMA)
    end
    self:consume(TT.RPAREN, "P006", "Expected ')' after parameters.")

    self:consume(TT.LBRACE, "P007", "Expected '{' before function body.")
    local body = self:block_statement()
    return AST.FuncDecl(name, params, body)
end

function Parser:statement()
    if self:match(TT.VAR) then
        return self:var_statement()
    elseif self:match(TT.IF) then
        return self:if_statement()
    elseif self:match(TT.WHILE) then
        return self:while_statement()
    elseif self:match(TT.RETURN) then
        return self:return_statement()
    elseif self:match(TT.LBRACE) then
        return self:block_statement()
    end

    return self:expression_statement()
end

function Parser:var_statement()
    local name = self:consume(TT.IDENTIFIER, "P001", "Expected variable name after 'var'.").lexeme
    local initializer = nil

    if self:match(TT.EQUAL) then
        initializer = self:expression()
    end

    self:consume(TT.SEMI, "P002", "Expected ';' after variable declaration.")
    return AST.VarStmt(name, initializer)
end

function Parser:if_statement()
    self:consume(TT.LPAREN, "P010", "Expected '(' after 'if'.")
    local condition = self:expression()
    self:consume(TT.RPAREN, "P011", "Expected ')' after if condition.")

    local then_branch = self:statement()
    local else_branch = nil

    if self:match(TT.ELSE) then
        else_branch = self:statement()
    end

    return AST.IfStmt(condition, then_branch, else_branch)
end

function Parser:while_statement()
    self:consume(TT.LPAREN, "P012", "Expected '(' after 'while'.")
    local condition = self:expression()
    self:consume(TT.RPAREN, "P013", "Expected ')' after condition.")

    local body = self:statement()
    return AST.WhileStmt(condition, body)
end

function Parser:return_statement()
    local value = nil
    if not self:check(TT.SEMI) then
        value = self:expression()
    end
    self:consume(TT.SEMI, "P014", "Expected ';' after return value.")
    return AST.ReturnStmt(value)
end

function Parser:block_statement()
    local statements = {}
    while not self:check(TT.RBRACE) and not self:at_end() do
        table.insert(statements, self:statement())
    end
    self:consume(TT.RBRACE, "P015", "Expected '}' after block.")
    return AST.BlockStmt(statements)
end

function Parser:expression_statement()
    local expr = self:expression()
    self:consume(TT.SEMI, "P016", "Expected ';' after expression.")
    return AST.ExprStmt(expr)
end

function Parser:expression()
    return self:assignment()
end

function Parser:assignment()
    local expr = self:equality()

    if self:match(TT.EQUAL) then
        local value = self:assignment()

        if expr.type == "VariableExpr" then
            return AST.AssignExpr(expr.name, value)
        end

        self:error("P017", "Invalid assignment target.", self:peek(-1))
    end

    return expr
end

function Parser:equality()
    local expr = self:comparison()
    while self:match(TT.EQUAL_EQUAL, TT.BANG_EQUAL) do
        local operator = self:peek(-1).lexeme
        local right = self:comparison()
        expr = AST.BinaryExpr(expr, operator, right)
    end
    return expr
end

function Parser:comparison()
    local expr = self:shift()
    while self:match(TT.GT, TT.GT_EQUAL, TT.LT, TT.LT_EQUAL) do
        local operator = self:peek(-1).lexeme
        local right = self:shift()
        expr = AST.BinaryExpr(expr, operator, right)
    end
    return expr
end

function Parser:shift()
    local expr = self:term()
    while self:match(TT.LSHIFT, TT.RSHIFT) do
        local operator = self:peek(-1).lexeme
        local right = self:term()
        expr = AST.BinaryExpr(expr, operator, right)
    end
    return expr
end

function Parser:term()
    local expr = self:factor()
    while self:match(TT.PLUS, TT.MINUS) do
        local operator = self:peek(-1).lexeme
        local right = self:factor()
        expr = AST.BinaryExpr(expr, operator, right)
    end
    return expr
end

function Parser:factor()
    local expr = self:unary()
    while self:match(TT.STAR, TT.SLASH, TT.PERCENT) do
        local operator = self:peek(-1).lexeme
        local right = self:unary()
        expr = AST.BinaryExpr(expr, operator, right)
    end
    return expr
end

function Parser:unary()
    if self:match(TT.BANG, TT.MINUS) then
        local operator = self:peek(-1).lexeme
        local right = self:unary()
        return AST.UnaryExpr(operator, right)
    end
    return self:call()
end

function Parser:call()
    local expr = self:primary()

    while true do
        if self:match(TT.LPAREN) then
            local args = {}
            if not self:check(TT.RPAREN) then
                repeat
                    table.insert(args, self:expression())
                until not self:match(TT.COMMA)
            end
            self:consume(TT.RPAREN, "P018", "Expected ')' after arguments.")
            expr = AST.CallExpr(expr, args)
        else
            break
        end
    end

    return expr
end

function Parser:primary()
    if self:match(TT.NULL) then return AST.LiteralExpr(nil) end
    if self:match(TT.TRUE) then return AST.LiteralExpr(1) end
    if self:match(TT.FALSE) then return AST.LiteralExpr(0) end
    if self:match(TT.NUMBER, TT.STRING, TT.CHAR) then return AST.LiteralExpr(self:peek(-1).literal or self:peek(-1).lexeme) end

    if self:match(TT.IDENTIFIER) then
        return AST.VariableExpr(self:peek(-1).lexeme)
    end

    if self:match(TT.LPAREN) then
        local expr = self:expression()
        self:consume(TT.RPAREN, "P019", "Expected ')' after expression.")
        return expr
    end

    self:error("P020", string.format("Unexpected token '%s'.", self:peek().lexeme))
end

return Parser