local canvas = require "includes/simple_canvas"

local canvas_callback = function(timestamp, width, height)
    local r = (timestamp * 11) % 255
    local g = (timestamp * 22) % 255
    local b = (timestamp * 33) % 255
    for i = 1, 25 do
        local x = math.cos(timestamp) * (100 + timestamp % 10)
        local y = math.sin(timestamp) * (100 + timestamp % 10)
        canvas(x + width / 2, y + height / 2, r, g, b)
        timestamp = timestamp + 0.01
    end
end

local document = require "/document"
local input = document.body:appendChild(document:createElement("input"))
input.type = "button"
input.value = "STOP"
input.style = "position:absolute;left:46.5vw;top:42vh;padding:25px"
local main_co = coroutine.running()
input.onclick = function() coroutine.resume(main_co) end

canvas = (require "includes/simple_canvas")("canvas", canvas_callback)

coroutine.suspend()
