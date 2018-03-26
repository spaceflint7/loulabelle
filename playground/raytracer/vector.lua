
--
-- vector
--

local new

local sqrt = assume_function(math.sqrt)

--
-- tostring
--

local function tostring(self)

    return "(x=" .. self[1]
        .. ",y=" .. self[2]
        .. ",z=" .. self[3] .. ")"

end

local set_normalized

--
-- metatable
--

local class_mt = { __index = {

--
-- set_normalized
--

set_normalized = function(self, x, y, z)

    assume_number(x, y, z)
    local len = x*x + y*y + z*z
    if len > 0 then
        JavaScript("$1=Math.sqrt($1)", len)
        --len = assume_number(sqrt(len))
        x = x / len
        y = y / len
        z = z / len
    end

    assume_nometa(self)
    self[1], self[2], self[3] = x, y, z

end,

--
-- set_subtracted
--

set_subtracted = function(self, a, b)

    assume_nometa(self, a, b)

    self[1] = assume_number(a[1]) - assume_number(b[1])
    self[2] = assume_number(a[2]) - assume_number(b[2])
    self[3] = assume_number(a[3]) - assume_number(b[3])

end,

--
-- set_subtracted_normalized
--

set_subtracted_normalized = function(self, a, b)

    assume_nometa(a, b)

    local x = assume_number(a[1]) - assume_number(b[1])
    local y = assume_number(a[2]) - assume_number(b[2])
    local z = assume_number(a[3]) - assume_number(b[3])

    set_normalized(self, x, y, z)

end,

--
-- set_add_multiply
--

set_add_multiply = function(self, a, b, c)

    assume_nometa(self, a, b)
    assume_number(c)

    self[1] = assume_number(a[1]) + assume_number(b[1]) * c
    self[2] = assume_number(a[2]) + assume_number(b[2]) * c
    self[3] = assume_number(a[3]) + assume_number(b[3]) * c

end,

--
-- dot
--

dot = function(a, b)

    assume_nometa(a)
    assume_nometa(b)

    -- xa * xb + ya * yb + za * zb
    return assume_number(a[1]) * assume_number(b[1])
    +      assume_number(a[2]) * assume_number(b[2])
    +      assume_number(a[3]) * assume_number(b[3])

end,

--
-- negate
--

--[[negate = function(self)

    assume_nometa(self)

    self[1] = -assume_number(self[1])
    self[2] = -assume_number(self[2])
    self[3] = -assume_number(self[3])

end,]]

--
-- reflect
--

--[[reflect = function(a, b)

    assume_nometa(a, b)

    local dot = 2 * (
           assume_number(a[1]) * assume_number(b[1])
    +      assume_number(a[2]) * assume_number(b[2])
    +      assume_number(a[3]) * assume_number(b[3]))
    b[1] = b[1] * dot - a[1]
    b[2] = b[2] * dot - a[2]
    b[3] = b[3] * dot - a[3]

end,]]

----------------------------------------------------
-- save
----------------------------------------------------

save = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)
    assume_number(jsindex)

    jsarray[jsindex + 0] = self[1]
    jsarray[jsindex + 1] = self[2]
    jsarray[jsindex + 2] = self[3]

    return jsindex + 3

end,

----------------------------------------------------
-- load
----------------------------------------------------

load = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)
    assume_number(jsindex)

    self[1] = jsarray[jsindex + 0]
    self[2] = jsarray[jsindex + 1]
    self[3] = jsarray[jsindex + 2]

    return jsindex + 3

end,

--
-- clone
--

clone = function(self)

    assume_nometa(self)
    return new(self[1], self[2], self[3])

end,

--
-- tostring
--

tostring = tostring,
},
__tostring = tostring,

}

set_normalized = class_mt.__index.set_normalized

--
-- constructor
--

new = function(x, y, z)

    local self = {
        --[[1,2,3]] x, y, z
    }
    setmetatable(self, class_mt)
    return self

end

return new

--compiler flags: --nodebug
