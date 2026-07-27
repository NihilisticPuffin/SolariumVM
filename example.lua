local VM = require "vm"

local Fibonacci = {
    const_pool = {
        20, --- Calculate Nth fibonacci number
        0, 1},
    func_table = {
        {address = 11, argc = 3}
    },
    bytecode = {
        0x01, 0x00,       --- CONSTANT 0
        0x01, 0x01,       --- CONSTANT 1
        0x01, 0x02,       --- CONSTANT 2
        0x1F, 0x00,       --- CALL 0
        0x21, 0x00,
        0xFF,             --- HALT

        0x08, 0x00,       --- GET_LOCAL 0
        0x01, 0x02,       --- CONSTANT 2
        0x19, 0x1B,       --- GREATER NOT (Same as <=)
        0x1D, 0x00, 0x14, --- JNZ return_b

        0x08, 0x00,       --- GET_LOCAL 0
        0x01, 0x02,       --- CONSTANT 2
        0x0B,             --- SUB
        0x09, 0x00,       --- SET_LOCAL 0

        0x08, 0x02,       --- GET_LOCAL 2
        0x08, 0x01,       --- GET_LOCAL 1
        0x08, 0x02,       --- GET_LOCAL 2
        0x0A,             --- ADD
        0x09, 0x02,       --- SET_LOCAL 2
        0x09, 0x01,       --- SET_LOCAL 1

        0x1F, 0x00,       --- CALL 0
        0x20,             --- RETURN
--- return_b:
        0x08, 0x02,       --- GET_LOCAL 2
        0x20              --- RETURN
    },
}

local LCG = { --- LCG PRNG
    const_pool = {
        1785108983, --- SEED
        1103515245, --- MULT
        12345,      --- INC
        2147483647, --- MOD (2^31 - 1)
    },
    func_table = {
        {address = 17, argc = 0}
    },
    bytecode = {
        0x01, 0x00, --- CONSTANT 0
    --- 0x21, 0x04, --- SYSCALL SYS_TIME (Replace CONSTANT 0 to use unix epoch as seed)
        0x07, 0x00, --- SET_GLOBAL 0
        0x1F, 0x00, --- CALL 0
        0x21, 0x00, --- SYSCALL SYS_PRINT
        0x1F, 0x00, --- CALL 0
        0x21, 0x00, --- SYSCALL SYS_PRINT
        0x1F, 0x00, --- CALL 0
        0x21, 0x00, --- SYSCALL SYS_PRINT
        0xFF,       --- HALT
        0x06, 0x00, --- GET_GLOBAL 0
        0x01, 0x01, --- CONSTANT 1
        0x0C,       --- MULT
        0x01, 0x02, --- CONSTANT 2
        0x0A,       --- ADD
        0x01, 0x03, --- CONSTANT 3
        0x0E,       --- MOD
        0x04,       --- DUP
        0x07, 0x00, --- SET_GLOBAL 0
        0x20,       --- RETURN
    }
}

local FileIO = {
    const_pool = {"test.txt", 1},
    bytecode = {
        0x01, 0x00, --- CONSTANT 0
        0x01, 0x01, --- CONSTANT 1
        0x21, 0x01, --- SYSCALL SYS_OPEN
        0x04,       --- DUP
        0x07, 0x00, --- SET_GLOBAL 0

        0x21, 0x02, --- SYSCALL SYS_READ

        0x06, 0x00, --- GET_GLOBAL 0
        0x21, 0x03, --- SYSCALL SYS_CLOSE
        0x21, 0x00, --- SYSCALL SYS_PRINT
        0xFF        --- HALT
    }
}
local vm = VM.new()
print("=== Fibonacci ===")
vm:load(Fibonacci):run()
print("=== LCG PRNG ===")
vm:reset():load(LCG):run()
print("=== File I/O ===")
vm:reset():load(FileIO):run()
