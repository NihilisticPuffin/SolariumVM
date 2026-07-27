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
        0x54, 0x00,       --- CALL 0
        0xFE, 0x00,       --- SYSCALL SYS_PRINT
        0xFF,             --- HALT

        0x12, 0x00,       --- GET_LOCAL 0
        0x01, 0x02,       --- CONSTANT 2
        0x41, 0x43,       --- GREATER NOT (Same as <=)
        0x52, 0x00, 0x14, --- JNZ return_b

        0x12, 0x00,       --- GET_LOCAL 0
        0x01, 0x02,       --- CONSTANT 2
        0x21,             --- SUB
        0x13, 0x00,       --- SET_LOCAL 0

        0x12, 0x02,       --- GET_LOCAL 2
        0x12, 0x01,       --- GET_LOCAL 1
        0x12, 0x02,       --- GET_LOCAL 2
        0x20,             --- ADD
        0x13, 0x02,       --- SET_LOCAL 2
        0x13, 0x01,       --- SET_LOCAL 1

        0x54, 0x00,       --- CALL 0
        0x55,             --- RETURN
--- return_b:
        0x12, 0x02,       --- GET_LOCAL 2
        0x55              --- RETURN
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
    --- 0xFE, 0x04, --- SYSCALL SYS_TIME (Replace CONSTANT 0 to use unix epoch as seed)
        0x11, 0x00, --- SET_GLOBAL 0
        0x54, 0x00, --- CALL 0
        0xFE, 0x00, --- SYSCALL SYS_PRINT
        0x54, 0x00, --- CALL 0
        0xFE, 0x00, --- SYSCALL SYS_PRINT
        0x54, 0x00, --- CALL 0
        0xFE, 0x00, --- SYSCALL SYS_PRINT
        0xFF,       --- HALT
        0x10, 0x00, --- GET_GLOBAL 0
        0x01, 0x01, --- CONSTANT 1
        0x22,       --- MULT
        0x01, 0x02, --- CONSTANT 2
        0x20,       --- ADD
        0x01, 0x03, --- CONSTANT 3
        0x24,       --- MOD
        0x04,       --- DUP
        0x11, 0x00, --- SET_GLOBAL 0
        0x55,       --- RETURN
    }
}

local FileIO = {
    const_pool = {"test.txt", 1},
    bytecode = {
        0x01, 0x00, --- CONSTANT 0
        0x01, 0x01, --- CONSTANT 1
        0xFE, 0x01, --- SYSCALL SYS_OPEN
        0x04,       --- DUP
        0x11, 0x00, --- SET_GLOBAL 0

        0xFE, 0x02, --- SYSCALL SYS_READ

        0x10, 0x00, --- GET_GLOBAL 0
        0xFE, 0x03, --- SYSCALL SYS_CLOSE
        0xFE, 0x00, --- SYSCALL SYS_PRINT
        0xFF        --- HALT
    }
}
local Assert = { --- assert(const_pool[0] == const_pool[1])
    const_pool = {0, 1, "Assert Failed", "Passed"},
    func_table = {
        {address = 14, argc = 2}
    },
    bytecode = {
        0x01, 0x00,
        0x01, 0x01,
        0x40,
        0x01, 0x02,
        0x54, 0x00,
        0x01, 0x03,
        0xFE, 0x00,
        0xFF,
        
        0x12, 0x00,
        0x52, 0x00, 0x06,
        0xFE, 0x00,
        0x01, 0x01,
        0xFE, 0x05,
        0x55
    }
}

local vm = VM.new()
print("=== Fibonacci ===")
vm:load(Fibonacci):run()
print("=== LCG PRNG ===")
vm:reset():load(LCG):run()
print("=== File I/O ===")
vm:reset():load(FileIO):run()

print("=== Assert ===")
vm:reset():load(Assert):run()