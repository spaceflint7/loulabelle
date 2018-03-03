
function fError(a,b,c)
    print("function entered with argument", a,b,c)
    if a > 600 then error(99) end
    if a > 400 then error("error_message") end
    return 99, 98, 97, 96
end

print "* normal"

local x1, x2, x3 = fError(111, 222, 333)
print("results:", x1, x2, x3)

print "* pcall"

x1, x2, x3 = pcall(fError, 111, 222, 333)
print("results:", x1, x2, x3)

x1, x2, x3 = pcall(fError, 456)
print("results:", x1, x2, x3)

x1, x2, x3 = pcall(fError, 789)
print("results:", x1, x2, x3)

print "* xpcall"

local x_count=0
tMsgH=function(a,b,c)
    print ("error handler args:", a, b, c)
    x_count = x_count + 1
    error("X" .. tostring(x_count))
    return "?"
end

x1, x2, x3 = xpcall(fError, nil, 111, 222, 333)
print("results:", x1, x2, x3)

--[[

x1, x2, x3 = xpcall(fError, tMsgH, 456)
print("results:", x1, x2, x3)

x1, x2, x3 = xpcall(fError, tMsgH, 789)
print("results:", x1, x2, x3)

print '---'
x1, x2, x3 = xpcall('ABC', tMsgH, 10101010)
print("results:", x1, x2, x3)

]]
