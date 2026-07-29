package.path = package.path .. ';src/?.lua'
local Lexer = require "Lexer"
local Parser = require "Parser"
local Compiler = require "Compiler"
local VM = require "VM"

local source = [[
    fn main() {
        fwrite(stdout, "What is your name: ");
        var name = fread(stdin, "*l");
        fwrite(stdout, "Hello, ");
        fwrite(stdout, name);
        fwrite(stdout, "!\n");
    }
]]


local tokens = Lexer.new(source):scan()
local ast = Parser.new(tokens, source):parse()
local program = Compiler.new(ast):compile()

local vm = VM.new():load(program):run()
if os.exit then
    os.exit(vm.exit_code)
end