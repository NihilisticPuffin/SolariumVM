return {
    NOP          = 0x00,

    --- [ Constants & Stack ]
    CONSTANT     = 0x01,
    NULL         = 0x02,
    POP          = 0x03,
    DUP          = 0x04,
    SWAP         = 0x05,
    
    --- [ Variables & Scoping ]
    GET_GLOBAL   = 0x10,
    SET_GLOBAL   = 0x11,
    GET_LOCAL    = 0x12,
    SET_LOCAL    = 0x13,

    --- [ Arithmetic Operations ]
    ADD          = 0x20,
    SUB          = 0x21,
    MUL          = 0x22,
    DIV          = 0x23,
    MOD          = 0x24,
    POW          = 0x25,
    INC          = 0x26,
    DEC          = 0x27,
    NEGATE       = 0x28,

    --- [ Bitwise Operations ]
    LSHIFT       = 0x30,
    RSHIFT       = 0x31,
    AND          = 0x32,
    OR           = 0x33,
    XOR          = 0x34,

    --- [ Comparison & Logical ]
    EQUAL        = 0x40,
    GREATER      = 0x41,
    LESS         = 0x42,
    NOT          = 0x43,

    --- [ Jumps & Flow Control ]
    JMP          = 0x50,
    JZ           = 0x51,
    JNZ          = 0x52,
    LOOP         = 0x53,
    CALL         = 0x54,
    RETURN       = 0x55,
    
    --- [ Memory & Indexing ]
    GET_INDEX    = 0x60,
    SET_INDEX    = 0x61,
    ARRAY        = 0x62,

    --- [ System ]
    SYSCALL      = 0xFE,
    HALT         = 0xFF,
}