
local Vector = {}
setmetatable(Vector, {

    __index = {
        class = 'Vector',
        self = function(v) return v end,
        print = function(v) print (v) end,
        constant = 1234
    },

    __add = function(a,b)
                return Vector(a.x+b.x, a.y+b.y)
            end,

    __call = function(v, x, y)
                return setmetatable({ x=x, y=y }, getmetatable(Vector))
            end,

    __tostring = function(v)
                return v.class.." X="..tostring(v.x).." Y="..tostring(v.y)
            end,

    __len = function(v) return ("length as string") end

})

local v1 = Vector(10, 20)
local v2 = Vector(30, 40)

print (v1)
print (v2)
print (v1 + v2)

print (v1:self().constant)
v1:self():print()

print (#v1)
