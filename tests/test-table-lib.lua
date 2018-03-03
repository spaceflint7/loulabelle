
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
table.insert(t,1,'First')
for k,v in pairs(t) do print (k,v) end print('---')
