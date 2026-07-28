return {
    -- Single-character tokens
    LPAREN      = "(",
    RPAREN      = ")",
    LBRACE      = "{",
    RBRACE      = "}",
    COMMA       = ",",
    SEMI        = ";",
    PLUS        = "+",
    MINUS       = "-",
    STAR        = "*",
    SLASH       = "/",
    PERCENT     = "%",
    CARET       = "^",
    EQUAL       = "=",
    BANG        = "!",
    LT          = "<",
    GT          = ">",
    AMP         = "&",
    PIPE        = "|",

    -- Multi-character tokens
    EQUAL_EQUAL = "==",
    BANG_EQUAL  = "!=",
    LT_EQUAL    = "<=",
    GT_EQUAL    = ">=",
    LSHIFT      = "<<",
    RSHIFT      = ">>",

    -- Literals & Identifiers
    IDENTIFIER  = "identifier",
    STRING      = "string",
    CHAR        = "char",
    NUMBER      = "number",

    -- Keywords
    ELSE        = "else",
    FUNC        = "fn",
    FOR         = "for",
    IF          = "if",
    NULL        = "null",
    RETURN      = "return",
    VAR         = "var",
    WHILE       = "while",

    -- End of File
    EOF         = "<EOF>",
}