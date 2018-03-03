
local str = "abcdefghi"
while true do
    do
        local idx = 1
        repeat
            ::start_loop::  -- ignored label
            repeat
                local x = str:sub(idx,idx)
                print (x)
                -- breaking out of the main 'while' loop:
                if x >= "e" then goto exit_program end
                -- breaking out of this loop
                goto exit_loop;
            until false
            ::exit_loop::
            idx = idx + 1
            -- continue into outer loop
            while true do
                goto continue_loop;
                print 'unreachable 1'
            end
            ::continue_loop::
        until idx == 99
    end
    print 'unreachable 2'
    ::cont::
end
::exit_program::
