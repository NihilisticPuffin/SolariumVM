local bit32 = require "bit32"

local SysCalls = {
    {
        name = "exit",
        id = 0x00,
        argc = 1,
        handler = function(vm)
            vm.exit_code = vm.stack:pop()
            vm.running = false
        end
    },
    {
        name = "time",
        id = 0x01,
        argc = 0,
        handler = function(vm)
            vm.stack:push(os.epoch and os.epoch("utc") or os.time())
        end
    },
    {
        name = "fopen",
        id = 0x02,
        argc = 2,
        handler = function(vm)
            local modes = { "r", "w", "a" }
            local mode = vm.stack:pop()
            local fh = io.open(vm.stack:pop(), mode)
            vm.stack:push(fh)
        end
    },
    {
        name = "fread",
        id = 0x03,
        argc = 2,
        handler = function(vm)
            local format = vm.stack:pop()
            local fh = vm.stack:pop()
            if fh then
                vm.stack:push(fh:read(format))
            end
        end
    },
    {
        name = "fwrite",
        id = 0x04,
        argc = 2,
        handler = function(vm)
            local data = vm.stack:pop()
            local fh = vm.stack:pop()
            if fh then
                local sucess, err = fh:write(data)
                vm.stack:push(sucess and 0 or 1)
            end
        end
    },
    {
        name = "fseek",
        id = 0x05,
        argc = 3,
        handler = function(vm)
            local offset = vm.stack:pop()
            local whence = vm.stack:pop()
            local fh = vm.stack:pop()
            if fh then
                local pos, err = fh:seek(whence, offset)
                vm.stack:push(pos)
            end
        end
    },
    {
        name = "ftell",
        id = 0x06,
        argc = 1,
        handler = function(vm)
            local fh = vm.stack:pop()
            if fh then
                local pos = fh:seek("cur", 0)
                vm.stack:push(pos)
            end
        end
    },
    {
        name = "fclose",
        id = 0x07,
        argc = 1,
        handler = function(vm)
            local fh = vm.stack:pop()
            fh:close()
        end
    },
}

SysCalls.calls = {}
SysCalls.handlers = {}

for _, syscall in ipairs(SysCalls) do
    SysCalls.calls[syscall.name] = syscall
    SysCalls.handlers[syscall.id] = syscall.handler
end

return SysCalls