local switch = require "switch"
local TT = require "TokenTypes"
local Token = function(type, lexeme, literal, line, column)
    return setmetatable({
        type = type,
        lexeme = lexeme,
        literal = literal,
        line = line,
        column = column
    }, {
        __tostring = function()
            return type .. ' ' .. lexeme .. ' ' .. (literal or '')
        end
    })
end

local keywords = {
    --- TODO: Add 'break' and 'continue' keywords
    ["else"]     = TT.ELSE,
    ["fn"]       = TT.FUNC,
    ["for"]      = TT.FOR,
    ["if"]       = TT.IF,
    ["null"]     = TT.NULL,
    ["return"]   = TT.RETURN,
    ["var"]      = TT.VAR,
    ["while"]    = TT.WHILE,
}

local escapes = {
    ['n']  = '\n',
    ['t']  = '\t',
    ['r']  = '\r',
    ['0']  = '\0',
    ['\\'] = '\\',
    ['"']  = '"',
    ['\''] = '\'',
}

local function noop() end

local function is_digit(c)
    return c >= '0' and c <= '9'
end

local function is_alpha(c)
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
end

local function is_alphanumeric(c)
    return is_alpha(c) or is_digit(c)
end

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

local Lexer = {}
Lexer.__index = Lexer

function Lexer.new(source, file)
    local self = setmetatable({
        source = source,
        file = file,
        start = 1,
        current = 1,
        line = 1,
        column = 0,
        tokens = {}
    }, Lexer)

    self.cases = {
        ['('] = self:SingleToken(TT.LPAREN),
        [')'] = self:SingleToken(TT.RPAREN),
        ['{'] = self:SingleToken(TT.LBRACE),
        ['}'] = self:SingleToken(TT.RBRACE),
        [','] = self:SingleToken(TT.COMMA),
        [';'] = self:SingleToken(TT.SEMI),
        ['<'] = self:MultiToken(TT.LT, {'=', TT.LT_EQUAL}, {'<', TT.LSHIFT}),
        ['>'] = self:MultiToken(TT.GT, {'=', TT.GT_EQUAL}, {'>', TT.RSHIFT}),
        ['+'] = self:SingleToken(TT.PLUS),
        ['-'] = self:SingleToken(TT.MINUS),
        ['*'] = self:SingleToken(TT.STAR),
        ['%'] = self:SingleToken(TT.PERCENT),
        ['^'] = self:SingleToken(TT.CARET),
        ['='] = self:SingleToken(TT.EQUAL),
        ['!'] = self:SingleToken(TT.BANG),
        ['&'] = self:SingleToken(TT.AMP),
        ['|'] = self:SingleToken(TT.PIPE),
        ['/'] = function() self:add_slash() end,
        ['"'] = function() self:add_string() end,
        ['\''] = function() self:add_char() end,
        [' '] = noop,
        ['\r'] = noop,
        ['\t'] = noop,
        ['\n'] = function() self.line = self.line + 1; self.column = 0 end,
        [switch.default] = function(c)
            if is_digit(c) then
                self:add_number()
            elseif is_alpha(c) then
                self:add_identifier()
            else
                self:error("L002", string.format("Unexpected character '%s'.", c))
            end
        end
    }

    return self
end

function Lexer:error(code, message, opts)
    opts = opts or {}
    local file   = opts.file or self.file or "<input>"
    local line   = opts.line or self.start_line or self.line
    local column = opts.column or self.start_column or self.column
    local length = opts.length or 1
    local note   = opts.note

    local line_text  = get_source_line(self.source, line)
    local line_label = tostring(line)
    local gutter     = string.rep(' ', #line_label)

    local out = {}
    table.insert(out, string.format("error[%s]: %s", code, message))
    table.insert(out, string.format("%s --> %s:%d:%d", gutter, file, line, column))
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
    os.exit(1)
end

function Lexer:SingleToken(type)
    return function() self:add_token(type) end
end

function Lexer:DoubleToken(c, type, type2)
    return function() self:add_token(self:match(c) and type or type2) end
end

function Lexer:MultiToken(default, ...)
    local sets = {...}
    return function()
        for _, set in ipairs(sets) do
            if self:match(set[1]) then
                self:add_token(set[2])
                return
            end
        end
        self:add_token(default)
    end
end

function Lexer:add_token(type, literal, text)
    text = text or self.source:sub(self.start, self.current - 1)
    table.insert(self.tokens, Token(type, text, literal, self.start_line or self.line, self.start_column or self.column))
end

function Lexer:at_end()
    return self.current > #self.source
end

function Lexer:advance()
    self.column = self.column + 1
    self.current = self.current + 1
    return self.source:sub(self.current - 1, self.current - 1)
end

function Lexer:match(expected)
    if self:at_end() or self.source:sub(self.current, self.current) ~= expected then 
        return false 
    end
    self:advance()
    return true
end

function Lexer:peek(offset)
    offset = offset or 0
    local idx = self.current + offset
    if idx > #self.source then return "" end
    return self.source:sub(idx, idx)
end

function Lexer:read_escape()
    local start_col = self.column
    self:advance()

    if self:at_end() or self:peek() == '\n' then
        self:error("L009", "Unterminated escape sequence.", {
            line = self.line,
            column = start_col,
            length = 1,
            note = "expected an escape character after '\\'"
        })
        return nil
    end

    local c = self:advance()
    local mapped = escapes[c]
    if not mapped then
        self:error("L010", "Unknown escape sequence '\\" .. c .. "'.", {
            line = self.line,
            column = start_col,
            length = 2,
            note = "supported escapes: \\n \\t \\r \\0 \\\\ \\\" \\'"
        })
        return nil
    end

    return mapped
end

function Lexer:add_char()
    if self:peek() == "'" then
        self:advance()
        self:error("L006", "Empty character literal.", {
            line = self.start_line,
            column = self.start_column,
            length = 2,
            note = "a character literal must contain exactly one character"
        })
        return
    end

    if self:peek() == "\n" or self:at_end() then
        self:error("L007", "Unterminated character literal.", {
            line = self.start_line,
            column = self.start_column,
            length = self.current - self.start,
            note = "expected a closing \"'\" before the end of input"
        })
        return
    end

    local c
    if self:peek() == '\\' then
        c = self:read_escape()
        if not c then return end
    else
        c = self:advance()
    end

    if self:peek() ~= "'" then
        while self:peek() ~= "'" and self:peek() ~= "\n" and not self:at_end() do
            if self:peek() == '\\' then
                self:advance()
            end
            self:advance()
        end

        if self:peek() == "'" then
            self:advance()
            self:error("L008", "Character literal may only contain one character.", {
                line = self.start_line,
                column = self.start_column,
                length = self.current - self.start,
                note = "use a string literal (\"...\") for multiple characters"
            })
        else
            self:error("L007", "Unterminated character literal.", {
                line = self.start_line,
                column = self.start_column,
                length = self.current - self.start,
                note = "expected a closing \"'\" before the end of input"
            })
        end
        return
    end

    self:advance()
    self:add_token(TT.CHAR, c)
end

function Lexer:add_string()
    local value = {}
    while self:peek() ~= '"' and self:peek() ~= "\n" and not self:at_end() do
        if self:peek() == '\\' then
            local c = self:read_escape()
            if not c then return end
            table.insert(value, c)
        else
            table.insert(value, self:advance())
        end
    end

    if self:at_end() or self:peek() == "\n" then
        self:error("L001", "Unterminated string.", {
            line = self.start_line,
            column = self.start_column,
            length = self.current - self.start,
            note = "expected a closing '\"' before the end of input"
        })
        return
    end

    self:advance()
    self:add_token(TT.STRING, table.concat(value))
end

function Lexer:add_slash()
    if self:match('/') then
        while self:peek() ~= '\n' and not self:at_end() do
            self:advance()
        end
        return
    end
    self:DoubleToken('=', TT.SLASH_EQUAL, TT.SLASH)()
end

function Lexer:add_number()
    while is_digit(self:peek()) do 
        self:advance() 
    end

    if self:peek() == '.' then
        if not is_digit(self:peek(1)) then
            self:advance()
            self:error("L003", "Malformed float: expected a digit after the decimal point.", {
                line = self.start_line,
                column = self.start_column,
                length = self.current - self.start,
                note = "trailing decimal points are not allowed"
            })
            return
        end

        self:advance()
        
        while is_digit(self:peek()) do
            self:advance() 
        end
    end

    if self:peek() == '.' then
        self:advance()
        while is_digit(self:peek()) do self:advance() end
        
        self:error("L004", "Malformed float: multiple decimal points detected.", {
            line = self.start_line,
            column = self.start_column,
            length = self.current - self.start,
            note = "a numeric literal can only contain one decimal point"
        })
        return
    end

    local lexeme = self.source:sub(self.start, self.current - 1)
    local value = tonumber(lexeme)
    
    if not value then
        self:error("L005", "Invalid number literal.", {
            line = self.start_line,
            column = self.start_column,
            length = self.current - self.start
        })
        return
    end

    self:add_token(TT.NUMBER, value)
end

function Lexer:add_identifier()
    while is_alphanumeric(self:peek()) do 
        self:advance() 
    end

    local text = self.source:sub(self.start, self.current - 1)
    self:add_token(keywords[text] or TT.IDENTIFIER)
end

function Lexer:scan()
    while not self:at_end() do
        self.start = self.current
        self.start_line = self.line
        self.start_column = self.column + 1
        switch(self:advance(), self.cases)
    end
    
    self.start = self.current
    self.start_line = self.line
    self.start_column = self.column + 1
    self:add_token(TT.EOF, nil, "<EOF>")
    return self.tokens
end

return Lexer