return {
    NOP          = 0x00,

    --- [ Constants & Stack ]
    CONSTANT     = 0x01,
    NULL         = 0x02,
    POP          = 0x03,
    DUP          = 0x04,
    SWAP         = 0x05,
    
    --- [ Variables & Scoping ]
    GET_GLOBAL   = 0x06,
    SET_GLOBAL   = 0x07,
    GET_LOCAL    = 0x08,
    SET_LOCAL    = 0x09,

    --- [ Arithmetic Operations ]
    ADD          = 0x0A,
    SUB          = 0x0B,
    MUL          = 0x0C,
    DIV          = 0x0D,
    MOD          = 0x0E,
    POW          = 0x0F,
    INC          = 0x10,
    DEC          = 0x11,
    NEGATE       = 0x12,

    --- [ Bitwise Operations ]
    LSHIFT       = 0x13,
    RSHIFT       = 0x14,
    AND          = 0x15,
    OR           = 0x16,
    XOR          = 0x17,

    --- [ Comparison & Logical ]
    EQUAL        = 0x18,
    GREATER      = 0x19,
    LESS         = 0x1A,
    NOT          = 0x1B,

    --- [ Jumps & Flow Control ]
    JMP          = 0x1C,
    JNZ          = 0x1D,
    LOOP         = 0x1E,
    CALL         = 0x1F,
    RETURN       = 0x20,
    
    --- [ System ]
    SYSCALL       = 0x21,
    HALT         = 0xFF,
}