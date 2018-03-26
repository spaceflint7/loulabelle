
--
-- sphere
--

local new

local vtmp = Vector(0, 0, 0)
local vec_save = assume_function(vtmp.save)
local vec_load = assume_function(vtmp.load)
local vec_clone = assume_function(vtmp.clone)
local vec_set_subtracted = assume_function(vtmp.set_subtracted)
local vec_set_subtracted_normalized = assume_function(vtmp.set_subtracted_normalized)
local dot = assume_function(vtmp.dot)

local sqrt = assume_function(math.sqrt)

--
-- tostring
--

local function tostring(self)

    return "(sphere,center=" .. tostring(self[1])
        .. ",radius=" .. tostring(self[3]) .. ")"

end

--
-- metatable
--

local class_mt = { __index = {

----------------------------------------------------
-- intersect
----------------------------------------------------

intersect = function(self, ro, rd)

    assume_nometa(self)
    local v = self[4]

    vec_set_subtracted(v, self[1], ro)
    local d = assume_number(dot(v, rd))

    if d >= 0 then

        local d2 = assume_number(dot(v, v)) - d * d
        local r2 = assume_number(self[2])

        if d2 <= r2 then

            d2 = assume_number(sqrt(r2 - d2))
            local t = d - d2
            if t < 0 then t = d + d2 end
            return t, self
        end
    end

end,

----------------------------------------------------
-- colorize
----------------------------------------------------

colorize = function(self, point, normal)

    assume_nometa(self)
    vec_set_subtracted_normalized(normal, point, self[1])

end,

----------------------------------------------------
-- save
----------------------------------------------------

save = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)

    -- store center vector
    jsindex = vec_save(self[1], jsarray, jsindex)
    assume_number(jsindex)

    -- store radius and radius2 values
    jsarray[jsindex]     = self[3]
    jsarray[jsindex + 1] = self[2]

    return jsindex + 2

end,

----------------------------------------------------
-- load
----------------------------------------------------

load = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)

    -- get center vector
    jsindex = vec_load(self[1], jsarray, jsindex)
    assume_number(jsindex)

    -- get radius and radius2
    self[3] = jsarray[jsindex]
    self[2] = jsarray[jsindex + 1]

    return jsindex + 2

end,

--
-- clone
--

clone = function(self)

    assume_nometa(self)
    return new(self[1], self[3], self[2])

end,

--
-- tostring
--

tostring = tostring,
},
__tostring = tostring,

}

--
-- constructor
--

new = function(center, radius, radius2)

    center = vec_clone(center or vtmp)
    radius = assume_number(radius) or 0
    radius2 = radius2 or (radius * radius)

    local self = {
        --[[1]] center,
        --[[2]] radius2,
        --[[3]] radius,
        --[[4]] vtmp,
    }

    setmetatable(self, class_mt)
    return self

end

return new

--compiler flags: --nodebug
