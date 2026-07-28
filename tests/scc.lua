package.path = package.path .. ';src/?.lua'
local Lexer = require "Lexer"
local Parser = require "Parser"
local Compiler = require "Compiler"
local VM = require "VM"

local source = [[
    fn fib(n, a, b) {
        if (n <= 1) return b;
        return fib(n-1, b, a+b);
    }
    fn main() {
       print(fib(20, 0, 1));
       return 0;
    }
]]


local tokens = Lexer.new(source):scan()
local ast = Parser.new(tokens, source):parse()
local program = Compiler.new(ast):compile()

local vm = VM.new():load(program):run()
os.exit(vm.exit_code)