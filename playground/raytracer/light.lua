
--
-- light
--

local new

local vtmp = Vector(0, 0, 0)
local vec_save = assume_function(vtmp.save)
local vec_load = assume_function(vtmp.load)
local vec_clone = assume_function(vtmp.clone)
local vec_set_subtracted_normalized = assume_function(vtmp.set_subtracted_normalized)
local vec_negate = assume_function(vtmp.negate)
local vec_dot = assume_function(vtmp.dot)

--
-- tostring
--

local function tostring(self)

    return "(light @ " .. tostring(self[1]) .. ")"

end

--
-- metatable
--

local class_mt = { __index = {

----------------------------------------------------
-- intersect
----------------------------------------------------

intersect = function(self, ro, rd)

end,

----------------------------------------------------
-- colorize
----------------------------------------------------

colorize = function(self, point, normal, group, group_intersect, hitobj)

    local origin = assume_nometa(self)[1]
    local dir = vtmp
    vec_set_subtracted_normalized(dir, point, origin)
    local dist, obj = group_intersect(group, origin, dir)
    if (not obj) or assume_nometa(obj) == hitobj then
        local contrib = assume_number(vec_dot(dir, normal))
        if contrib < 0 then
            return -contrib
        end
    end
    return 0

end,

----------------------------------------------------
-- save
----------------------------------------------------

save = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)

    return vec_save(self[1], jsarray, jsindex)

end,

----------------------------------------------------
-- load
----------------------------------------------------

load = function(self, jsarray, jsindex)

    assume_nometa(self)
    assume_nometa(jsarray)

    return vec_load(self[1], jsarray, jsindex)

end,

--
-- clone
--

clone = function(self)

    assume_nometa(self)
    return new(self[1])

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

new = function(point)

    local self = {
        --[[1]] vec_clone(point or vtmp),
    }

    setmetatable(self, class_mt)
    return self

end

return new

--compiler flags: --nodebug
