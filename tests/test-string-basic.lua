
print (tostring(0x5678), string.len(0x5678))

print ('<'..''..'>')
print (string.rep('X', -1, ',')..'Z')
print (string.rep('X', 0, nil)..'Z')
print (string.rep('X', 1, ',')..'Z')
print (string.rep('X', 2, ',')..'Z')
print (string.rep('X', 3)..'Z')

print (("Hello"):lower())
print (("World"):upper())
print (("abcdef"):reverse())

print (string.sub("Hello,World",2,-2))
print (string.sub("Hello,World",4,-4))
print (string.sub("Hello,World",6,-6))
print (string.sub("Hello,World",6,6))
print (string.sub("Hello,World",7))
print (string.sub("Hello,World",-5))

print (string.char())
print (string.char(65,66,67,68,69))

print (string.byte("Hello,World"))
print (string.byte("Hello,World", -1))
print (string.byte("Hello,World", 1, -1))
print (string.byte("Hello,World", -4, -1))
