
----------------------------------------------------
-- import modules into global variables
----------------------------------------------------

if package.playground then

    --
    -- when running in the playground, our rendering
    -- threads (which will be spawned in a web worker)
    -- don't have the playground require() to load
    -- stuff from the playground database.  so we are
    -- going to pre-load everything here, and pass
    -- the compiled javascript text to the web worker
    --

    print 'Loading modules...'

    Vector_chunk = load(io.load("raytracer/vector"), nil, nil, nil)
    Sphere_chunk = load(io.load("raytracer/sphere"), nil, nil, nil)
    Light_chunk = load(io.load("raytracer/light"), nil, nil, nil)
    Group_chunk = load(io.load("raytracer/group"), nil, nil, nil)
    Tracer_chunk = load(io.load("raytracer/tracer"), nil, nil, nil)

    print 'Modules loaded.'

    --
    -- on the main thread, we can just run the
    -- loaded/compiled chunks, and store their
    -- return values, as if we require()d them
    --

    Vector = Vector_chunk()
    Sphere = Sphere_chunk()
    Light = Light_chunk()
    Group = Group_chunk()

else

    --
    -- standalone version can just require stuff
    --

    Vector = require "vector"
    Sphere = require "sphere"
    Light  = require "light"
    Group  = require "group"

end

local comain

coroutine.spawn(function()

----------------------------------------------------
-- define scene
----------------------------------------------------

local group = Group()
local group_save = assume_function(group.save)
group:define(Light(Vector(0,0,0)), 'light')
group:define(Sphere(Vector(0,0,0),0))

local my_sphere1 = Sphere(Vector(0,0,20),2.5)
local my_sphere2 = Sphere(Vector(0,0,20),2.5)
group:insert(my_sphere1, Vector(0,0,1))
group:insert(my_sphere2, Vector(1,1,0))
group:insert(Sphere(Vector(0,0,20),8), Vector(0,1,0))
group:insert(Light(Vector(100,0,-100)))

local sin = assume_function(math.sin)
local cos = assume_function(math.cos)

----------------------------------------------------
-- create canvas
----------------------------------------------------

local canvas = { width=320, height=240 }

(function ()

    assert(canvas.width % 4 == 0, 'canvas width not divisable by 4')
    local tmp
    JavaScript("$1=document.body.appendChild(document.createElement('canvas'))", tmp)
    canvas.elem = tmp
    JavaScript("$1.width=$2", tmp, canvas.width)
    JavaScript("$1.height=$2", tmp, canvas.height)
    JavaScript("$1=$1.getContext('2d',{alpha:false})", tmp)
    canvas.ctx = tmp
    JavaScript("$1=$2.createImageData($3,$4)", tmp, canvas.ctx, canvas.width, canvas.height)
    canvas.image = tmp
    JavaScript("$1=$2.width", tmp, canvas.image)
    assert(tmp == canvas.width, 'canvas width != image width')
    JavaScript("$1=$2.height", tmp, canvas.image)
    assert(tmp == canvas.height, 'canvas width != image width')
    JavaScript("$1=new Uint32Array($2.data.buffer)", tmp, canvas.image)
    canvas.view = tmp

    if package.playground then
        JavaScript("$1.onclick=$2", canvas.elem,
            (coroutine.jscallback(function()
                print 'Stopping raytracer'
                coroutine.resume(comain)
            end)))
    end

end)()

----------------------------------------------------
-- handle response from worker
----------------------------------------------------

JavaScript("var time0,time1")

local workers = {}
local n
JavaScript("$1=window.navigator.hardwareConcurrency", n)
local run_workers

local function onmessage(msg)

    local tdiff

    local array, worker, view
    JavaScript("$1=$1.data", msg)
    JavaScript("[$2,$3]=[$1.array,$1.worker]", msg, array, worker)

    JavaScript("$1=new Uint32Array($2)", view, array)
    worker = workers[worker]
    JavaScript("$1.set($2,$3)", canvas.view, view, worker.y * canvas.width)
    worker.array = array

    local num_ready = 0
    for i = 1, n do
        if workers[i].array then num_ready = num_ready + 1 end
    end
    if num_ready == n then

        JavaScript("time1 = performance.now() / 1000")
        JavaScript("$1=time1-time0", tdiff)

        JavaScript("$1.putImageData($2,0,0)", canvas.ctx, canvas.image)

    JavaScript("var p=document.getElementById('p')")
    JavaScript("if(!p){")
    JavaScript("p=document.createElement('p')")
    JavaScript("p.id='p'")
    JavaScript("p.style='position:absolute;top:0;color:yellow'")
    JavaScript("document.body.appendChild(p)}")
    local str = tdiff .. ' (' .. n .. ' threads)'
    if package.playground then
        str = str .. '<br>Click to stop'
    end
    JavaScript("p.innerHTML=$1", str)

    run_workers()
    end

end

----------------------------------------------------
-- select source for web worker:
-- use worker.js file if standalone version,
-- load worker_js text if running in playground
----------------------------------------------------

local worker_url, worker_msg

if package.playground then

    worker_url = io.load("worker_js")
    JavaScript("$1=window.URL.createObjectURL(new Blob([$1],{type:'text/javascript'}))", worker_url)
    -- we can't require() in the worker, but we can
    -- send JavaScript function text for our chunks
    local Vector_js, Sphere_js, Light_js, Group_js, Tracer_js
    JavaScript("$2=$1.toString()", Vector_chunk, Vector_js)
    JavaScript("$2=$1.toString()", Sphere_chunk, Sphere_js)
    JavaScript("$2=$1.toString()", Light_chunk, Light_js)
    JavaScript("$2=$1.toString()", Group_chunk, Group_js)
    JavaScript("$2=$1.toString()", Tracer_chunk, Tracer_js)
    worker_msg = { core_url = _G.url .. "../core.js",
        Vector = Vector_js, Sphere = Sphere_js,
        Light = Light_js, Group = Group_js,
        main = Tracer_js }
else                -- standalone
    worker_url = 'worker.js'
    worker_msg = 'tracer.js'
end

----------------------------------------------------
-- create workers
----------------------------------------------------

local region_height = canvas.height / n
local region_width = canvas.width

for i = 1, n do

    local worker, array, view
    local y0 = region_height * (i - 1)
    local y1 = y0 + region_height - 1
    JavaScript("$1=new Worker($2)", worker, worker_url)
    JavaScript("$1.postMessage($2)", worker, worker_msg)
    coroutine.fastcall(function()
        JavaScript("$1.onmessage=$2", worker, (coroutine.jscallback(onmessage)))
    end)
    JavaScript("$1=new ArrayBuffer($2)", array, region_width * region_height * 4)
    workers[i] = { worker = worker, y = y0, array = array }

end

g_workers = workers
g_num_workers = n

----------------------------------------------------
-- run workers
----------------------------------------------------

local timestamp = 0
assume_number(timestamp)

run_workers = function()

    local center = my_sphere1[1]
    center[1] = cos(timestamp / 66) * 15
    center[2] = sin(timestamp / 66) * 10 * cos(timestamp / 66)
    center[3] = sin(timestamp / 66) * 15 + 22

    center = my_sphere2[1]
    center[1] = 0
    center[2] = sin(100 - timestamp / 55) * 20
    center[3] = cos(100 - timestamp / 55) * 15 + 22

    timestamp = timestamp + 1

    JavaScript("time0 = performance.now() / 1000")

    local database = group_save(group)

    for i = 1, n do

        local worker = workers[i]
        JavaScript("$1.postMessage({array:$2,y0:$3,y1:$4,width:$5,worker:$6,scene:$7},[$2])",
            worker.worker, worker.array,
            worker.y, worker.y + region_height - 1,
            region_width, i, database)
        worker.array = nil

    end

end

coroutine.fastcall(run_workers)

end)

--
-- Suspend while raytracer is running,
-- stop all worker threads when we wake up
--

comain = coroutine.running()
coroutine.suspend()

for i = 1, g_num_workers do
    print ('Stopping worker #' .. i)
    local worker = g_workers[i].worker
    JavaScript("$1.terminate()", worker)
end
print 'Stopped'

--compiler flags: --nodebug
