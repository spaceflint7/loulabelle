
----------------------------------------------------
-- group object
----------------------------------------------------

local new

----------------------------------------------------

local vec_one = Vector(1,1,1)
local vec_save = assume_function(vec_one.save)
local vec_load = assume_function(vec_one.load)

----------------------------------------------------

local infinity = assume_number(math.huge)

local obj_types = assume_nometa({[0]=0})
local lights    = assume_nometa({[0]=0})

local intersect, save, load

----------------------------------------------------
-- tostring
----------------------------------------------------

local function tostring(self)

    local n_types = #obj_types
    local n_objs = self[0]

    return "scene with " .. n_types .. " types"
        .. " and " .. n_objs .. " objects"

end

----------------------------------------------------
-- define
----------------------------------------------------

local function prepare_object(obj, obj_type, obj_type_index, color)

    assume_nometa(obj, obj_type)
    obj[-1] = obj_type_index
    obj[-2] = obj_type[2]   -- intersect
    obj[-3] = obj_type[3]   -- material
    obj[-4] = obj_type[4]   -- save
    obj[-5] = obj_type[5]   -- load
    obj[-7] = obj_type[7]   -- is light
    obj[-8] = color or vec_one

end

----------------------------------------------------

local class_mt = { __index = {

----------------------------------------------------
-- define
----------------------------------------------------

define = function(self, obj, kind)

    local obj_mt = getmetatable(obj)
    local n = obj_types[0] + 1
    obj_types[n] = {
        --[[1]] obj,
        --[[2]] obj.intersect,
        --[[3]] obj.colorize,
        --[[4]] obj.save,
        --[[5]] obj.load,
        --[[6]] obj.clone,
        --[[7]] kind,
    }
    obj_types[assume_string(obj_mt)] = n
    obj_types[0] = n
    return n

end,

----------------------------------------------------
-- insert
----------------------------------------------------

insert = function(self, obj, color)

    assume_nometa(self)

    -- get the type index for the object
    local obj_mt = getmetatable(obj)
    local obj_type_index = obj_types[obj_mt]
    assert(tonumber(obj_type_index), 'unknown object type')
    local obj_type = obj_types[obj_type_index]

    -- prepare object to add to group
    prepare_object(obj, obj_type, obj_type_index, color)

    if obj_type[7] == 'light' then
        -- light object goes in the lights table,
        -- which is shared by all groups
        self = lights
    end

    -- store the object in self[n],
    -- update object count in self[0]
    local n = assume_number(self[0]) + 1
    self[n] = obj
    self[0] = n

end,

----------------------------------------------------
-- intersect
----------------------------------------------------

intersect = function(self, ro, rd)

    assume_nometa(self)

    local min_dist = infinity
    local min_obj, dist

    for i = 1, assume_number(self[0]) do

        local obj = assume_nometa(self[i])

        local obj_intersect = assume_function(obj[-2])
        assume_untyped(obj)
        dist, obj = obj_intersect(obj, ro, rd)
        assume_number(dist)

        if dist and dist < min_dist then

            min_dist = dist
            min_obj = obj
        end
    end

    return min_dist, min_obj

end,

----------------------------------------------------
-- colorize
----------------------------------------------------

colorize = function(self, obj, point, normal)

    assume_function(assume_nometa(obj)[-3])(obj, point, normal)
    local color = assume_nometa(assume_nometa(obj)[-8])
    return color[1], color[2], color[3]

end,

----------------------------------------------------
-- lighting
----------------------------------------------------

lighting = function(self, hitobj, point, normal)

    local sum = 0
    for i = 1, assume_number(lights[0]) do
        local obj = assume_nometa(lights[i])
        local contrib = assume_number(
            assume_function(obj[-3])(obj, point, normal, self, intersect, hitobj))
        if contrib > 0 then sum = sum + contrib end
    end

    if sum > 1 then sum = 1 end
    return sum

end,

----------------------------------------------------
-- save
----------------------------------------------------

save = function(self, jsarray, jsindex)

    assume_nometa(self, jsarray)

    local return_jsarray
    if not jsarray then
        JavaScript("$1={array:[]};", jsarray)
        jsindex = save(lights, jsarray, 0)
        return_jsarray = jsarray
    end

    assume_number(jsindex)
    local n = self[0]
    jsarray[jsindex] = n
    jsindex = jsindex + 1

    for i = 1, assume_number(n) do

        local obj = assume_nometa(self[i])

        -- store object type index from obj[-1]
        jsarray[jsindex] = obj[-1]

        -- call obj:save(jsarray, jsindex)
        local obj_save = assume_function(obj[-4])
        jsindex = assume_number(obj_save(obj, jsarray, jsindex + 1))

        -- call vec:save(jsarray, jsindex) on color
        jsindex = assume_number(vec_save(obj[-8], jsarray, jsindex))

    end

    return return_jsarray or jsindex

end,

----------------------------------------------------
-- load
----------------------------------------------------

load = function(self, jsarray, jsindex)

    assume_nometa(self, jsarray)

    if not jsindex then
        jsindex = load(lights, jsarray, 0)
    end

    assume_number(jsindex)
    local n = jsarray[jsindex]
    self[0] = n
    jsindex = jsindex + 1

    for i = 1, assume_number(n) do

        -- get object type index from the array
        local obj_type_index = assume_number(jsarray[jsindex])

        -- get scene object at index i
        local obj = assume_nometa(self[i])
        if obj == nil or assume_number(obj[-1]) ~= obj_type_index then
            -- create if no scene object, or different type
            local obj_type = assume_nometa(obj_types[obj_type_index])
            local obj_clone = assume_function(obj_type[6])  -- clone
            obj = assume_nometa(obj_clone(obj_type[1]))     -- object
            prepare_object(obj, obj_type, obj_type_index, Vector(0,0,0))
            self[i] = obj
        end

        -- call obj:load(jsarray, jsindex)
        local obj_load = assume_function(obj[-5])
        jsindex = assume_number(obj_load(obj, jsarray, jsindex + 1))

        -- call vec:load(jsarray, jsindex) on color
        jsindex = assume_number(vec_load(obj[-8], jsarray, jsindex))
    end

    return jsindex

end,

----------------------------------------------------
-- tostring
----------------------------------------------------

tostring = tostring,
},
__tostring = tostring,

}

intersect = class_mt.__index.intersect
save = class_mt.__index.save
load = class_mt.__index.load

----------------------------------------------------
-- constructor
----------------------------------------------------

new = function()

    local self = {
        [-1]={},     -- types
        [0]=0,       -- count
    }

    setmetatable(self, class_mt)
    return self

end

return new

--compiler flags: --nodebug
