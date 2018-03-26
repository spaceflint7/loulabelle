
--local TIMES = 8555111
local TIMES = 555111

function clock(start1,start2)
    JavaScript("if (typeof window === 'undefined') {\z
        if (!$1) return process.hrtime();\z
        var end = process.hrtime([$1,$2]);\z
        return [Math.round((end[0]*1000) + (end[1]/1000000))];\z
    } else {\z
        if (!$1) return [performance.now()];\z
        var end = performance.now();\z
        return [end - $1];\z
    }", start1, start2)
end

function timeIt(f, TIMES, msg)
    local start1, start2 = clock()
    local sum = 0
    for i = 0, TIMES-1 do
        sum = sum + f(i)
    end
    local diff = clock(start1, start2)
    print(msg, 'SUM=', sum, 'TIME=', diff)
end

function f1a(i) return i*i end

t = { [1]=1, k=2 }
function f2a(i) local z = 'k' return t[1]+t.k+t[z] end

print "TIMING SLOW 1" timeIt(f1a, TIMES, 'SLOW')
print "TIMING FAST 1" coroutine.fastcall(timeIt, f1a, TIMES, 'FAST')

print "TIMING SLOW 2" timeIt(f2a, TIMES, 'SLOW')
print "TIMING FAST 2" coroutine.fastcall(timeIt, f2a, TIMES, 'FAST')

-----------------------------------

--
-- test upvalue references in fastcall
--

local function gen_test()

    local v0
    local v = 'v1'
    return function()
        return (function() return v end)()
    end

end

local function test_test(f)

    local v = 'v2'
    coroutine.fastcall(f)

end

local f = gen_test()
assert(f() == coroutine.fastcall(f))

--------------------------------------

print '-----ALL OK-----'
