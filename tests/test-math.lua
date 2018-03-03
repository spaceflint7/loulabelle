
if not math.acosh then
    local rngseed = 1
    math.random = function(a)
        local r = math.sin(rngseed)*10000
        r = r - math.floor(r)
        rngseed = rngseed + 1
        return r
    end
end

--print ("Formatted", "Printed")

local printnum=function(n)
    n = tostring(math.floor(n * 1000000) / 1000000)
    -- print(string.format("%6f", n), n)
    print(string.format("%6f", n))
end

for i=1,10 do
    local n1 = math.random()
    n1 = math.pow(n1,math.random()*math.exp(i))
    local m, e = math.frexp(n1)
    local n2 = math.ldexp(m, e)
    printnum(n2)
end
