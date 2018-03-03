
--
-- very simple canvas wrapper.  sample usage:
--
-- local canvas = require "includes/simple_canvas"
--
--      require this file, which returns a factory function
--      to create a canvas.
--
-- local function callback(timestamp, width, height)
--      canvas(
--
-- canvas = canvas(id, callback)
-- arguments:
--      id is HTML id for canvas, can be passed as nil.
--      callback, a function that will be invoked
--      through requestAnimationFrame.
--
-- for example use, see 'samples/plot2d'
--

local function canvas_gen_funcs(canvas)

    ::update_stack_frame::
    JavaScript("var ctx=$1", canvas.ctx)
    JavaScript("var img=ctx.getImageData(0,0,$1,$2)", canvas.width, canvas.height)
    JavaScript("var w=img.width")
    JavaScript("var data=img.data")

    local pixel = function(x, y, r, g, b, a)

        ::update_stack_frame::
        JavaScript("var i=(($2|0)*w+($1|0))*4", x, y)

        if r ~= nil then
            JavaScript("data[i]=$1|0",   r)
            JavaScript("data[i+1]=$1|0", g)
            JavaScript("data[i+2]=$1|0", b)
            JavaScript("data[i+3]=$1|0", a or 255)
        else
            JavaScript("$1=data[i]",   r)
            JavaScript("$1=data[i+1]", g)
            JavaScript("$1=data[i+2]", b)
            JavaScript("$1=data[i+3]", a)
            return r, g, b, a
        end
    end

    local paint = function()
        ::update_stack_frame::
        JavaScript("ctx.putImageData(img,0,0)")
    end

    return pixel, paint

end

local function canvas_setup_callback(canvas_elem, callback, paint, width, height)

    local wrapper
    local last_timestamp = 0
    wrapper = coroutine.jscallback(
        function(_callback, _width, _height, timestamp)

            local ok, err =
                pcall(_callback, timestamp, _width, _height)
            if not ok then print (err) end

            paint()

            -- request another animation frame, as long
            -- as the program is still running.  assume
            -- that if the canvas is no longer in the
            -- DOM, it is because the program stopped.

            if timestamp - last_timestamp > 1000 then
                local alive
                JavaScript("$2=document.body.contains($1)", canvas_elem, alive)
                if not alive then return end
                last_timestamp = timestamp
            end
            JavaScript("window.requestAnimationFrame($1)", wrapper)
        end, callback, width, height)

    JavaScript("window.requestAnimationFrame($1)", wrapper)

end


local function canvas_create(canvas_id, callback_func)

    local canvas_elem
    JavaScript("$1=document.getElementById($2)", canvas_elem, canvas_id)
    JavaScript("if($1==null){", canvas_elem)
    JavaScript(     "$1=document.createElement('canvas')", canvas_elem)
    JavaScript(     "$1.id=$2", canvas_elem, canvas_id or 'canvas')
    JavaScript(     "$1.width=window.innerWidth", canvas_elem)
    JavaScript(     "$1.height=window.innerHeight", canvas_elem)
    JavaScript(     "document.body.appendChild($1)", canvas_elem)
    JavaScript("}")

    local canvas_ctx, canvas_width, canvas_height
    JavaScript("$1=$2.getContext('2d')", canvas_ctx, canvas_elem)
    JavaScript("$1=$2.width", canvas_width, canvas_elem)
    JavaScript("$1=$2.height", canvas_height, canvas_elem)

    local t = {
        elem = canvas_elem, id = canvas_id, ctx = canvas_ctx,
        width = canvas_width, height = canvas_height,
        image = canvas_image, data = canvas_data
    }
    local pixel, paint = canvas_gen_funcs(t)
    canvas_setup_callback(canvas_elem, callback_func, paint, canvas_width, canvas_height)

    return pixel

end

return canvas_create
