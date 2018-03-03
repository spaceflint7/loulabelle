
local document = require("document")
mobile = false

--
-- print_table
--

function print_table(t,spaces)

    if type(t) ~= "table" then print ("print_table called on " .. type(t)) return end

    if not spaces then
        print "Table = {"
        spaces = 4
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            print (string.rep(" ",spaces) .. "Key " .. tostring(k) .. " = Table {")
            print_table(v, spaces + 4)
        else
            print (string.rep(" ",spaces) .. "Key " .. tostring(k) .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
        end
    end

    print (string.rep(" ",spaces - 4) .. "}")
end

--
-- call_server
--

function call_server(form)

    local res, err = document.load_form("serverdb.php", form)
    if err then err = "HTTP error code " .. err .. " for operation " .. form.op
    else
        local idx = type(res) == "string" and res:find("<JSON>{", 1, true)
        if idx then
            res = document.parse_json(res:sub(idx + 6))
            if res.error then err = res.error end
        else err = "Server reports error: " .. tostring(res) end
    end
    if err then
        show_error(err)
        res = nil
    end
    return res, err

end

--
-- modal_dialog
--

modal_dialog_active = false
local modal_dialog_suspended = false

function modal_dialog(modal)

    if type(modal) == "string" then
        modal = document:getElementById(modal)
    end
    if not modal then return end

    if mobile then
        document.body:appendChild(modal)
    end

    local modal_co = coroutine.running()
    local function close_modal(event, button)
        if modal_dialog_suspended then
            coroutine.resume(modal_co, button)
        end
    end

    modal.onclick = function(event)
        if event.target == modal then close_modal() end
    end

    local onkeyup = coroutine.jscallback(function(event)
        local key
        JavaScript("$1=$2.key", key, event)
        if key == 'Escape' then close_modal() end
        if key == 'Enter' then
            local buttons = modal:getElementsByClassName("modal-button")
            if #buttons > 0 then close_modal(nil, buttons[1]) end
        end
    end)
    JavaScript("window.addEventListener('keyup',$1)", onkeyup)

    local close = modal:getElementsByClassName("modal-cancel")
    if #close > 0 then
        close[1].onclick = close_modal
    end

    local buttons = modal:getElementsByClassName("modal-button")
    for i = 1, #buttons do
        buttons[i].onclick = function()
            close_modal(nil, buttons[i])
        end
    end

    modal.style.display = "block"
    rawset(modal, "close", function()
        modal.style.display = "none"
        modal_dialog_active = false
    end)

    local focus = modal:getElementsByClassName("modal-focus")
    focus = focus[1]
    if focus then focus:focus() end

    modal_dialog_active = true

    modal_dialog_suspended = true
    local button = coroutine.suspend()
    modal_dialog_suspended = false

    JavaScript("window.removeEventListener('keyup',$1)", onkeyup)
    return modal, button

end

--
-- switch_view
--

local console_section, editor_section, active_section

function switch_view(which)

    if which == "finder" and not mobile then return end

    local old_active_section = active_section

    if which == "console" then
        if not console_section then
            console_section = require "console"
        end
        active_section = console_section

    elseif which == "editor" then
        if not editor_section then
            editor_section = require "editor"
        end
        active_section = editor_section

    elseif which == "finder" then
        if not finder_section then
            finder_section = document:getElementById("finder-section")
        end
        active_section = finder_section
    end

    if not rawequal(active_section, old_active_section) then

        local old_finder, new_finder = false, false
        if old_active_section then
            old_finder = rawequal(old_active_section, finder_section)
            old_active_section.style.display = "none"
        end
        new_finder = rawequal(active_section, finder_section)
        active_section.style.display = "block"

        if mobile then

            if old_finder ~= new_finder then
                local lpane = document:getElementById("index-pane-left")
                local rpane = document:getElementById("index-pane-right")
                lpane.style.display = new_finder and "block" or "none"
                rpane.style.display = new_finder and "none" or "block"
            end

            local r_button = document:getElementById("status-run-button")
            if editor_section and rawequal(active_section, editor_section) then
                r_button.style.display = "inline"
            elseif console_section and rawequal(active_section, console_section) then
                r_button.style.display = "none"
            end

            document:resizeCallback(true)
        end

    end

end

--
-- show_status
--

local status_section, status_section_text

function show_status(text, error)

    if not status_section then
        status_section = document:getElementById("status-section")
    end

    if status_section_text ~= text then

        status_section.innerHTML = text
        status_section_text = text

        if status_section_text == "" then
            status_section.style.display = "none"
        else
            status_section.style.display = mobile and "inline" or "inline-block"
            status_section.style.backgroundColor = error and "red" or "transparent"
            status_section.style.width = error and "100%" or ""
        end
    end

    document:resizeCallback(true)

end

function show_error(text) show_status(text, true) end

--
-- load_codemirror
--

local codemirror_mutex = coroutine.mutex()

function load_codemirror(mode)

    codemirror_mutex:lock()
    if not codemirror_mutex.loaded_base then
        JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/codemirror.min.js')")
        JavaScript("yield*$L.require_css('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/codemirror.min.css')")
        codemirror_mutex.loaded = true
    end
    if mode == "lua" and not codemirror_mutex.loaded_lua then
        JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/mode/lua/lua.min.js')")
        codemirror_mutex.loaded_lua = true
    end
    if mode == "css" and not codemirror_mutex.loaded_css then
        JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/mode/css/css.min.js')")
        codemirror_mutex.loaded_css = true
    end
    if mode == "xml" and not codemirror_mutex.loaded_xml then
        JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/mode/xml/xml.min.js')")
        codemirror_mutex.loaded_xml = true
    end
    if mode == "js" and not codemirror_mutex.loaded_js then
        JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.34.0/mode/javascript/javascript.min.js')")
        codemirror_mutex.loaded_js = true
    end
    codemirror_mutex:unlock()
    if mode == "html" and not codemirror_mutex.loaded_html then
        load_codemirror("css")
        load_codemirror("xml")
        load_codemirror("js")
    end

end

--
-- main
--

-- on Chrome on Android, 100vh includes the address bar,
-- which causes undesired vertical scrolling.
document:resizeCallback(function(w,h)
    local panes = document:getElementById("index-panes")
    h = tostring(h) .. 'px'
    panes.style.height = h
end)

local menu_button = document:getElementById("status-menu-button")
if menu_button:getComputedStyle().display ~= "none" then
    mobile = true
    switch_view("finder")
    menu_button.onclick = function()
        if back_button_switch_editor then
            switch_view("editor")
            back_button_switch_editor = false
            if editor_focus then editor_focus() end
        else
            switch_view("finder")
        end
    end
end

coroutine.spawn(require "finder")
