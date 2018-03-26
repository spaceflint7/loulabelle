
local console_widget
local console_container
local console_status_text

--
-- console_run
--

local function console_run_placeholder(folder_name, file_name)

    --
    -- this is a placeholder that is used only while
    -- the console is initializing.  when initialization
    -- is complete, the console_run global is updated
    --

    while console_busy == nil or console_busy == true do
        coroutine.sleep(25)
    end

    console_run(folder_name, file_name)
end

--
-- install_listener
--

local function install_listener(handler)

    local callback = function(event)
        local window, data
        JavaScript("$1=$2.source", window, event)
        JavaScript("$1=$2.data", data, event)
        local msg = coroutine.jsconvert(data)
        msg.window = window
        handler(msg)
    end

    JavaScript("window.addEventListener('message',$1,false)",
                (coroutine.jscallback(callback)))
end

--
-- post
--

local function post(msg)

    local window = msg.window
    assert(window ~= nil)
    msg.window = nil
    msg = coroutine.jsconvert(nil, msg)
    JavaScript("$1.postMessage($2,'*')", window, msg)

end

--
-- local_main
--

local local_main
local_main = function(document, iframe, input)

    --
    -- create text editor for console
    --

    console_busy = true

    local function on_key_func(cm, key, e)
        if key == "Tab" or key == "Shift-Tab" then input:focus() end
    end

    if not console_codemirror_loaded_once then
        local exception
        load_codemirror()
        JavaScript("try{")
        JavaScript("$1=CodeMirror.fromTextArea(document.getElementById('console-placeholder'),{mode:'none',readOnly:true,scrollbarStyle:'null',tabindex:0})", console_widget)
        JavaScript("$1.on('keyHandled',$2)", console_widget, (coroutine.jscallback(on_key_func)))
        console_codemirror_loaded_once = true
        JavaScript("}catch(e){$1='JS '+e.toString()}", exception)
        if exception then
            show_error(exception)
            return
        end
    end

    local console_iframe = document:fromElement(iframe)

    if not console_container then
        local console_container = document:getElementById("console-container")
        document:resizeCallback(function(w,h)
            local status = document:getElementById("status-section")
            h = h - status.offsetHeight - input.offsetHeight - 10
            h = tostring(h) .. 'px'
            console_container.style.height = h
            console_iframe.style.height = h
            h = tostring(status.offsetHeight) .. 'px'
            console_iframe.style.top = h
        end)
    end

    console_focus = function()
        show_status(console_status_text or "Console")
        if not mobile then input:focus() end
    end
    console_focus()

    --
    -- wait for iframe to initialize
    --

    local window
    JavaScript("$1=$2.contentWindow", window, iframe)

    local ping_time = tostring(os.time())
    local pong_time
    local local_co
    local printqueue = {}
    local inputqueue = {}

    input.onkeypress = function(event)
        if event.key == "Enter" then
            inputqueue[#inputqueue+1] = input.value:trim()
            input.value = ""
            if local_co then coroutine.resume(local_co) end
        end -- else if event.key == "ArrowUp" then
    end

    input.oninput = function() document:resizeCallback(true) end

    install_listener(function(msg)
        if msg.type == "pong" then pong_time = msg.time
        elseif msg.type == "print" then
            printqueue[#printqueue+1] = msg.text
            if local_co then coroutine.resume(local_co) end
        elseif msg.type == "ready" then
            console_busy = false
            if console_status_text and console_status_text:sub(1,1) == 'R' then
                console_status_text = "Finished r" .. console_status_text:sub(2)
            else
                console_status_text = "Console"
            end
            show_status(console_status_text)
            console_iframe.style.pointerEvents = "none"
        end
    end)

    for i = 1, 100 do
        post { window=window, type="ping", time=ping_time, url=document.URL }
        coroutine.sleep(100)
        if pong_time == ping_time then break end
    end

    if pong_time ~= ping_time then
        show_error('Failed to connect to iframe.  Refresh page to retry.')
        return
    end

    console_run = function(folder_name, file_name)
        if console_busy or #inputqueue ~= 0 then
            show_error("Console is already running a command at this time")
        else
            console_iframe.style.pointerEvents = "all"
            console_status_text = 'Running <span class="filename">' .. file_name .. '</span> in folder <span class="filename">' .. folder_name .. '</span>'
            console_focus()
            inputqueue[1] = 'require "' .. folder_name .. '/' .. file_name .. '"'
            if local_co then coroutine.resume(local_co) end
        end
    end

    console_busy = false

    --
    --
    --

    while true do

        if #printqueue == 0 and #inputqueue == 0 then
            local_co = coroutine.running()
            coroutine.suspend()
            local_co = nil
        end

        if #printqueue ~= 0 then
            local text = table.concat(printqueue, '\n') .. '\n'
            JavaScript("$1.replaceRange($2,{line:$1.lineCount()})", console_widget, text)
            JavaScript("$1.execCommand('goDocEnd')", console_widget)
            printqueue = {}
        end

        if #inputqueue ~= 0 then
            local cmd = table.remove(inputqueue,1)
            if not console_busy and cmd:sub(1,1) == '=' then
                cmd = 'return ' .. cmd:sub(2)
            end
            console_busy = true
            if cmd == "/clear" then
                JavaScript("$1.setValue('')", console_widget)
                console_busy = false
            elseif cmd == "/restart" then
                console_run = console_run_placeholder
                console_focus = nil
                local iframe_new
                JavaScript("$2=$1.cloneNode()", iframe, iframe_new)
                JavaScript("$1.parentNode.replaceChild($2,$1)", iframe, iframe_new)
                coroutine.spawn(local_main, document, iframe_new, input)
                do return end
            else
                post { window=window, type="input", text=cmd }
            end
        end
    end

end

--
-- remote_compile
--

local function remote_compile(Loulabelle, res)

    local debug = true
    res.source_text = res.source_text:rtrim()
    if res.source_text:endswith("--nodebug") then
        debug = false
    end

    local filepath = res.folder_name .. '/' .. res.file_name
    local func, err = Loulabelle(
            res.file_name .. ".lua",
            res.source_text, {
                env = _G, debug = debug })
    if err then
        err = err .. ' in file ' .. filepath
        error(err, 2)
    end

    return func

end

--
-- remote_load
--

local function remote_load(Loulabelle)

    local load = _G.load

    return function(text, source, mode, env)

        if type(text) ~= 'string' then
            return load(text, source, mode, env)
        end

        local res = {
            folder_name = '(load)',
            file_name = '(load)',
            source_text = text
        }

        local func = remote_compile(Loulabelle, res)
        if func and env then
            func = load(func, nil, nil, env)
        end
        return func

    end
end

--
-- remote_require
--

local function remote_require(Loulabelle, document)

    local stack = {}
    local cache = {}

    return function(path, require_mode)

        local result = cache[path]
        if result then return result end

        if require_mode then
            if path == "/document" then
                return document
            end
        end

        local slash, folder, file = path:index("/")
        if slash then
            folder = path:sub(1,slash-1):trim()
            file = path:sub(slash+1)
            if require_mode then stack[#stack+1] = folder end
        else
            folder = (#stack > 0) and stack[#stack] or "?"
            file = path
        end

        local form = {
            op = 'read_file',
            folder = folder,
            file = file
        }
        local res, err = document.load_form("serverdb.php", form)

        if err then err = "HTTP error code " .. err .. " for operation " .. form.op
        else
            local idx = type(res) == "string" and res:find("<JSON>{", 1, true)
            if idx then
                res = document.parse_json(res:sub(idx + 6))
                if res.error then err = res.error end
            else err = "Server reports error: " .. tostring(res) end
        end

        if err then error(err,3) end

        if not require_mode then result = res.source_text
        else

            result = remote_compile(Loulabelle, res)
            result = result()

            if result == nil then
                result = cache[path]
                if result == nil then result = true end
            end

            if slash and #stack > 1 then stack[#stack] = nil end
        end

        cache[path] = result
        return result
    end
end

--
-- remote_main
--

local function remote_main()

    --
    -- load compiler.  note that compiler was actually
    -- already preloaded by console.html, so we are
    -- just getting a reference to that preloaded module
    --

    local Loulabelle = require "Loulabelle"

    package.playground = true
    load = remote_load(Loulabelle)

    --
    -- wait for initial message from iframe host
    --

    local host
    local remote_co = coroutine.running()
    local inputqueue = {}

    install_listener(function(msg)
        if msg.type == "ping" then
            _G.url = msg.url:sub(1, msg.url:rindex('/'))
            host = msg.window
            if host ~= nil then
                msg.type = "pong"
                post (msg)
            end
        elseif msg.type == "input" then
            if host ~= nil then
                if inputqueue.waiting then
                    inputqueue.waiting = nil
                    coroutine.resume(remote_co, msg.text)
                else
                    inputqueue[#inputqueue+1] = msg.text
                end
            end
        end
    end)

    while not host do
        coroutine.sleep(100)
    end

    --
    -- io.read, io.write
    --

    if not io then io = {} end
    local io = io

    local read_input = function(arg)
        assert(arg == nil, "read() does not support any format strings")
        local line
        if #inputqueue ~= 0 then
            line = table.remove(inputqueue,1)
        else
            inputqueue.waiting = true
            line = coroutine.suspend()
        end
        return line
    end
    io.read = read_input

    io.writequeue = {}
    io.write = function(...)
        for i = 1, select('#', ...) do
            local v = select(i, ...)
            if type(v) == 'number' then
                io.writequeue[#io.writequeue+1] = tostring(v)
            else
                assert(type(v) == 'string', 'write() supports only numbers or strings')
                while true do
                    local idx = v:index('\n')
                    if not idx then break end
                    if idx ~= 1 then
                        io.writequeue[#io.writequeue+1] = v:sub(1,idx-1)
                    end
                    v = v:sub(idx + 1)
                    local s = table.concat(io.writequeue)
                    io.writequeue = {}
                    post { window=host, type="print", text=s }
                end
                io.writequeue[#io.writequeue+1] = v
            end
        end
    end

    --
    -- coroutine creation functions
    --

    local old_coroutine = {
        create=coroutine.create,
        wrap=coroutine.wrap,
        spawn=coroutine.spawn,
        status=coroutine.status
    }

    local active_coroutines = { }

    coroutine.create = function(...)
        local co = old_coroutine.create(...)
        if co then active_coroutines[co] = true end
        return co
    end

    coroutine.wrap = function(...)
        local fn, co = old_coroutine.wrap(...)
        if co then active_coroutines[co] = true end
        return fn, co
    end

    coroutine.spawn = function(...)
        local co = old_coroutine.spawn(...)
        if co then active_coroutines[co] = true end
        return co
    end

    local function wait_for_coroutines()
        local display = true
        while true do
            local nco = 0
            for co,st in pairs(active_coroutines) do
                if st then
                    st = old_coroutine.status(co)
                    if st ~= 'dead' then nco = nco + 1
                    else active_coroutines[co] = false end
                end
            end
            if nco == 0 then break end
            if display then
                print ('(waiting for ' .. tostring(nco) .. ' coroutines to finish)')
                display = false
            end
            coroutine.sleep(250)
        end
        JavaScript("document.body.innerHTML=''")
        post { window=host, type="ready" }
    end

    --
    -- wait for console input
    --

    local document = require "document"

    post { window=host, type="print", text="\n\z
        Loulabelle Playground console ready.\n\z
        Console commands: /clear /restart\n" }

    printwriter = function(s)
        post { window=host, type="print", text=s }
    end

    while true do
        local text = read_input()
        post { window=host, type="print", text='>>>' .. text }
        local func, err = Loulabelle('(console)', text, { env = _G, debug = true })
        if err then post { window=host, type="print", text=err }
        else
            local require_or_load = remote_require(Loulabelle, document)
            require = function(s) return require_or_load((s), true) end
            io.load = function(s) return require_or_load((s), false) end
            --
            local ok, res = xpcall(func, function(s)
                s = debug.traceback(s, 2)
                -- discard stack trace beyond the initial xpcall
                local idx = s:rindex('xpcall')
                s = s:sub(1,idx)
                idx = s:rindex('\n')
                s = s:sub(1,idx)
                print(s)
            end)
            if ok and res then
                post { window=host, type="print", text=res }
            end
        end
        --
        old_coroutine.spawn(wait_for_coroutines)
    end

end

--
-- main
--

if not call_server then return remote_main() end

console_run = console_run_placeholder

local document = require("document")

local console_html, err = document.load_html("console.css", "console.html")
if err then show_error(err) return end
local console_section = document:getElementById("console-section")
console_section.innerHTML = console_html.body.innerHTML

local iframe = document:getElementById("console-iframe")
iframe = rawget(iframe, "dom_elem")
local input = document:getElementById("console-input")
coroutine.spawn(local_main, document, iframe, input)

return console_section
