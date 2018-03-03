

--
-- variables scope
--

local x = 5
repeat
    print('Loop Iteration')
    local x = 1
until x == 1
print(x)


--
-- multiple results
--

function x(...) return ... end
function y(...) return 4, 5, 6, ... end

print ('global x?', _G.x ~= nil)
print ('global y?', _G.y ~= nil)

print (x(1,2,3))
print (y(1,2,3))

local flag = false
local f = function() return "OneOfTwo", "TwoOfTwo" end
local a, b = flag and f() or "JustOne"
print (a,b)


--
-- select
--


print(select('#'))
print(select('#', 123, 456, 789))
print(select(1, 123, 456, 789))
print(select(2, 123, 456, 789))
print(select(3, 123, 456, 789))
print(select(-3, 123, 456, 789))
print(select(4, 123, 456, 789))     -- empty line
print(tonumber("X"))                -- prints 'nil'

