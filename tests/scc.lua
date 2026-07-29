package.path = package.path .. ';src/?.lua'
local Lexer = require "Lexer"
local Parser = require "Parser"
local Compiler = require "Compiler"
local VM = require "VM"

local source = [[
    fn fsize(path) {
        var file = fopen(path, "r");
        var size = fseek(file, "end", 0);
        fclose(file);
        return size;
    }
    fn main() {
        fwrite(stdout, fsize("tests/test.txt"));
        return 6;
    }
]]


local tokens = Lexer.new(source):scan()
local ast = Parser.new(tokens, source):parse()
local program = Compiler.new(ast):compile()

local vm = VM.new():load(program):run()
if os.exit then
    os.exit(vm.exit_code)
end