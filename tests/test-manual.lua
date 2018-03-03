
--
-- next
--

t = { 1000, 2000, 3000, 4000 }

k1 = next(t)
while k1 do
    print ('K1', k1)
    k2 = next(t)
    while k2 do
        print ('K2', k2)
        k2 = next(t, k2)
    end
    k1 = next(t, k1)
end

--
-- next
--

local main = coroutine.running()
local f = function(three, four, six)
    print (three)
    coroutine.resume(main)
    print (four)
    coroutine.suspend()
    print (six)
end
print '#1'
local co = coroutine.spawn(f, '#3', '#4', '#6')
print '#2'
coroutine.suspend()
print '#5'
coroutine.resume(co)

--
-- regex
--

if not string.regex then
    string.regex = function(s) return s end
end

local pattern = string.regex("([A-Z])([a-z]*)")
local iterator = string.gmatch("Quick Brown Fox", pattern)
while true do
    local cap1, cap2 = iterator()
    if cap1 then print (cap1, cap2) else break end
end
