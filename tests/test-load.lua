
function t1(arg)
    print '-------------'
    print 'Global Table:'
    for k,v in pairs(_G) do print(k) end
    --[[if t2 then
        local t3 = load(string.dump(t2), nil, nil)
        t3()
    end]]
    ;(function()
        print ('LUA VERSION IS', _VERSION)
    end)()
end

t1()
local dummy_env = { print = print, pairs = pairs, string = string, load = load }
dummy_env._G = dummy_env
local t2 = load(string.dump(t1), nil, nil, dummy_env)
dummy_env.t2 = t2
t2()
