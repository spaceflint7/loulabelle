
string.regex = string.regex or function(s) return s end

local pattern_wcap = string.regex("([A-Z])([a-z]*)([ ]?)")  -- with capture
local pattern_ncap = string.regex("[A-Z][a-z]*[ ]?")        -- no captures

--print "12345678901234567890"
--print "Quick Brown Fox"

--print ("find  own @", string.find("Quick Brown Fox", "own", nil, true))
--print ("match own @", string.match("Quick Brown Fox", "own\\"))

print "FIND-1"

local idx = -20
while idx do
    local idx1, idx2, cap1, cap2, cap3, cap4 = string.find("Quick Brown Fox", pattern_wcap, idx + 1)
    print ("find ", idx1, idx2, cap1, cap2, '<'..tostring(cap3)..'>', cap4)
    idx = idx1
end

print "FIND-2"

local idx = -20
while idx do
    local idx1, idx2, cap1, cap2, cap3, cap4 = string.find("Quick Brown Fox", pattern_ncap, idx + 1)
    print ("find ", idx1, idx2, cap1, cap2, '<'..tostring(cap3)..'>', cap4)
    idx = idx1
end

print "MATCH-1"

local idx = -20
while idx do
    local cap1, cap2, cap3, cap4 = string.match("Quick Brown Fox", pattern_wcap, idx + 1)
    print ("match ", idx, cap1, cap2, '<'..tostring(cap3)..'>', cap4)
    idx = cap1 and (idx + 2)
end

print "MATCH-2"

local idx = -20
while idx do
    local cap1, cap2 = string.match("Quick Brown Fox", pattern_ncap, idx + 1)
    print ("match ", idx, '<'..tostring(cap1)..'>', cap2)
    idx = cap1 and (idx + 2)
end

print "GMATCH-1"

local iter = string.gmatch("Quick Brown Fox", pattern_wcap)
while true do
    local cap1, cap2, cap3, cap4 = iter()
    print (cap1,cap2,'<'..tostring(cap3)..'>', cap4)
    if not cap1 then break end
end

print "GMATCH-2"

local iter = string.gmatch("Quick Brown Fox", pattern_ncap)
while true do
    local cap1, cap2, cap3, cap4 = iter()
    print (cap1,cap2,'<'..tostring(cap3)..'>', cap4)
    if not cap1 then break end
end

print "GSUB-1"

print (string.gsub("12345: Hello, World Today: 54321", pattern_wcap, "<%1:%2:%3>"))
print (string.gsub("12345: Hello, World Today: 54321", pattern_wcap, "<%0>"))
print (string.gsub("12345: Hello, World Today: 54321", pattern_ncap, "<%1>"))

print (string.gsub("12345: Hello, World Today: 54321", pattern_wcap, function(a,b,c) print(a,b,c) return false end))
print (string.gsub("12345: Hello, World Today: 54321", pattern_wcap, function(a,b,c) print(a,b,c) return false end))

local t_rep = setmetatable({}, {__index=function(t,k) print("index event for",k) return string.upper(k) end })
print (string.gsub("12345: Hello, World Today: 54321", pattern_ncap, t_rep))
