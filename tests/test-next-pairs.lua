
--
-- this is not a good test, and produces different results
-- between Lua and Loulabelle, due to different ordering
-- of Lua tables vs JavaScript hashes
--

local t = { 123, 456, 111, 789, a='val_a', b='val_b', c=nil, [true]='val_true', [false]='val_false' }
t[3]=nil

local i, j
repeat
    i = next(t, i)
    if i == 4 then
        print("out of order 'next' for 2 = ", next(t, 2))
        print("out of order 'next' for 'c' = ", next(t, 'c'))
        i = nil
    end
until i == nil

print('NEXT LOOP')
local i
while true do
    i = next(t, i)
    if i == nil then break end
    print(i, t[i])
end

print('PAIRS LOOP')
local t_save=t
for k,v in pairs(t) do
    print(k,v)
    if (#tostring(k) < 20 and t) then
        t[tostring(k)..tostring(k)]='HELLO'
    else t = nil end
end

print('IPAIRS LOOP')
t=t_save
t[3]=102030
for k,v in ipairs(t) do
    print(k,v)
end

print('TABLE CONSTRUCTION WITH MULTIPLE VALUES')
local function ret123() return 4, 5, 6 end
t = { 1, 2, 3, ret123() }
for k,v in pairs(t) do print (k,v) end

print('TABLE DELETE LOOP')
t[0x5p-5] = 'Test'
t['Test'] = 'Test'
while true do
    local k = next(t)
    if not k then break end
    print ('DELETING', k)
    t[k] = nil
end
for k,v in pairs(t) do print (k,v) end

print('ANOTHER ITERATION TEST')
local t = {}
t[-7] = 'MinusSeven'
t[-1] = 'MinusOne'
t[0] = 'Zero'
t[1] = 'PlusOne'
t[7] = 'PlusSeven'
print 'IPAIRS'
for k,v in ipairs(t) do print (k,v) end
print 'PAIRS'
for k,v in pairs(t) do print (k,v) end

print '-----ALL OK-----'
