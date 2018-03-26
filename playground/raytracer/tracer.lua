
----------------------------------------------------
-- import modules into global variables
----------------------------------------------------

if not Vector then

    --
    -- if running under playground, then worker_js
    -- already assigned these globals.  if running
    -- standalone, we need to require these.
    --

    Vector = require "vector"
    Sphere = require "sphere"
    Light  = require "light"
    Group  = require "group"

end

----------------------------------------------------

local infinity = math.huge
assume_number(infinity)

----------------------------------------------------

local vec_zero = Vector(0,0,0)
local vec_set_normalized = assume_function(vec_zero.set_normalized)
local vec_set_add_multiply = assume_function(vec_zero.set_add_multiply)

local vec_point = Vector(0,0,0)
local vec_normal = Vector(0,0,0)

----------------------------------------------------

local group = Group()
group:define(Light(Vector(0,0,0)), 'light')
group:define(Sphere(Vector(0,0,0),0))

local group_load = assume_function(group.load)
local group_intersect = assume_function(group.intersect)
local group_colorize = assume_function(group.colorize)
local group_lighting = assume_function(group.lighting)

----------------------------------------------------
-- ray_trace_pixel
----------------------------------------------------

local function ray_trace_pixel(ro, rd)

    local dist, obj = group_intersect(group, ro, rd)
    if not obj then return 0.11,0.11,0.22 end

    --
    -- calculate color and normal at intersection
    --

    vec_set_add_multiply(vec_point, ro, rd, dist)
    local r, g, b = group_colorize(group, obj, vec_point, vec_normal)
    local diffuse = group_lighting(group, obj, vec_point, vec_normal)
    assume_number(r, g, b, diffuse)

    if (not diffuse) or diffuse < 0.1 then diffuse = 0.1 end
    diffuse = diffuse * 0.75
    r = r * diffuse
    g = g * diffuse
    b = b * diffuse
    if r > 1 then r = 1 end
    if g > 1 then g = 1 end
    if b > 1 then b = 1 end
    return r, g, b

end

----------------------------------------------------
-- onmessage event
----------------------------------------------------

local dir = Vector()

local function onmessage(msg)

    --
    -- grab the rendering parameters
    -- from the incoming message
    --

    local array, y0, y1, w, worker, view
    JavaScript("$1=$1.data", msg)
    local scene_jsobj
    JavaScript("[$2,$3,$4,$5,$6,$7]=[$1.array,$1.y0,$1.y1,$1.width,$1.worker,$1.scene]", msg, array, y0, y1, w, worker, scene_jsobj)
    group_load(group, scene_jsobj, nil)
    assume_number(y0,y1,w)
    JavaScript("$1=new Uint32Array($2)", view, array)

    --
    -- trace a ray through each pixel.  note that
    -- canvas size is hardcoded 320x240.
    --

    for y = y0, y1 do
        local yy = (1 - 2 * ((y + 0.5) / 240))
        for x = 0, w do
            local xx = (2 * ((x + 0.5) / 320) - 1)
            vec_set_normalized(dir, xx, yy, 1)
            local r, g, b = ray_trace_pixel(vec_zero, dir, 1)
            local y = y - y0
            JavaScript("$4[($6|0)*$7+($5|0)]=0xFF000000|((($3*255)&255)<<16)|((($2*255)&255)<<8)|(($1*255)&255)", r, g, b, view, x, y, w)
        end
    end
    JavaScript("postMessage({array:$1,worker:$2},[$1])", array, worker)
end

coroutine.fastcall(function()
    JavaScript("onmessage=$1", (coroutine.jscallback(onmessage)))
end)

--compiler flags: --nodebug
