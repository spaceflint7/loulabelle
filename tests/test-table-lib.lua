
t = { 'a', 'b', 'c' }

print (t[1], t[2], t[3])
print (t['1'], t['2'], t['3'])

print (table.concat(t, ':'))

table.insert(t, 'z')

for k,v in pairs(t) do print (k,v) end print('---')

print(table.remove(t, 4))

for k,v in pairs(t) do print (k,v) end print('---')

t = table.pack('x', 'y', 666, 'z')
for k,v in pairs(t) do print (k,v) end print('---')

print (table.unpack(t)) print('---')

for i=5, 55 do t[i] = string.char((i % 13) + 65) end
table.sort(t, function(a,b)
    a=tostring(a)
    b=tostring(b)
    print ('comparing', a, b)
    return (tostring(a)<tostring(b))
end)
for k,v in pairs(t) do print (k,v) end print('---')

t = {  }
t[1] = '1'
t[-70] = 'Minus'
t[7.5] = 'Dot'
t["X"] = 'Y'
table.insert(t,1,'First')
t[2] = 'Second'
t[12] = 'Twelve'
t2 = {}
for k,v in pairs(t) do
    table.insert(t2, tostring(k) .. '\t' .. tostring(v))
end
table.sort(t2)
print (table.concat(t2, "\n"))
print('---')
