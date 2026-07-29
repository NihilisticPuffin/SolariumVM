package.path = package.path .. ';src/?.lua'
local Lexer = require "Lexer"
local Parser = require "Parser"
local Compiler = require "Compiler"
local VM = require "VM"

if arg[1] == nil then
    error("Usage: scc <file>", 0)
end

local fh = io.open(arg[1], "r")
local source
if fh then
    source = fh:read("*a")
    fh:close()
end

if source == nil then
    error("Could not read file: " .. arg[1], 0)
end

local tokens = Lexer.new(source):scan()
local ast = Parser.new(tokens, source):parse()
local program = Compiler.new(ast):compile()

local vm = VM.new():load(program):run()
if os.exit then
    os.exit(vm.exit_code)
end