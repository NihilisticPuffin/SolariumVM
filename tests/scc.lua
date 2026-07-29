package.path = package.path .. ';src/?.lua'
local Lexer = require "Lexer"
local Parser = require "Parser"
local Compiler = require "Compiler"
local VM = require "VM"

local source = [[
    fn main() {
        var count = fread(stdin, "*l");
        count = cast("number", count);
        while (count > 0) {
            fwrite(stdout, count);
            fwrite(stdout, "\n");
            count = count - 1;
        }
    }
]]


local tokens = Lexer.new(source):scan()
local ast = Parser.new(tokens, source):parse()
local program = Compiler.new(ast):compile()

local vm = VM.new():load(program):run()
if os.exit then
    os.exit(vm.exit_code)
end