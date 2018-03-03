
local document = require("document")

local editor_mutex = coroutine.mutex()
local editor_widget
local editor_changed = -1
local editor_saving = false
local editor_file_deleted = false
local editor_file_created = false
local editor_folder_name, editor_file_name
local editor_status_text
local editor_Loulabelle

--
-- edit_file
--

function edit_file(folder_name, file_name, create_file)

    --
    -- if already saving the file being edited, then
    -- wait for the save operation to finish.
    -- or else if the file being edited needs to be
    -- saved, then do a synchronous save operation.
    --

    if editor_saving then
        while editor_saving do
            editor_mutex:lock()
            editor_mutex:unlock()
        end
    elseif editor_changed > 0 then
        edit_save()
    end

    --
    -- read the text for the file to edit
    --

    local file_text, err = read_file(folder_name, file_name)
    if create_file then
        if file_text then
            err = 'File already exists:  <span class="filename">' .. file_name .. '</span> in folder <span class="filename">' .. folder_name .. '</span>'
            show_error(err)
        elseif err and err:startswith("File not found") then
            err = nil
            file_text = "(New file)"
        end
    end
    if err then return end

    editor_status_text = nil
    editor_folder_name, editor_file_name = nil, nil

    --
    -- initialize the editor component on first use
    --

    editor_mutex:lock()
    if not editor_mutex.loaded then

        local function on_update_func()
            editor_changed = editor_changed + 1
        end
        local function auto_save_func()
            while true do
                coroutine.sleep(3000)
                edit_save()
            end
        end

        --[[local ext = file_name:rindex('.')
        if ext then ext = file_name:sub(ext + 1):tolower()
        else ext = "lua" end]]

        load_codemirror("lua")
        JavaScript("try{")
        JavaScript("$1=CodeMirror.fromTextArea(document.getElementById('editor-placeholder'),{lineNumbers:true,indentUnit:4,tabindex:0,inputStyle:'textarea'})", editor_widget)
        JavaScript("$1.on('change',$2)", editor_widget, (coroutine.jscallback(on_update_func)))

        -- text input on Android:  (1) disableBrowserMagic
        -- function in CodeMirror does not set the autocomplete
        -- attribute, and (2) Chrome on Android does not
        -- respect autocomplete on contenteditable divs.
        -- we fix this by setting inputStyle:'textarea' above,
        -- and then fixing the TextArea element manually here:

        local input_widget
        JavaScript("$2=$1.getInputField()", editor_widget, input_widget)
        input_widget = document:fromElement(input_widget)
        input_widget.attributes["autocomplete"] = "off"
        input_widget.attributes["autocapitalize"] = "none"

        JavaScript("}catch(e){$1='JS '+e.toString()}", editor_status_text)
        if editor_status_text then
            show_error(editor_status_text)
            return
        end

        coroutine.spawn(auto_save_func)

        editor_mutex.loaded = true
    end
    editor_mutex:unlock()

    --
    -- update the text in the editor component
    --

    if not editor_status_text then

        editor_changed = -1
        JavaScript("$1.setValue($2)", editor_widget, file_text)
        JavaScript("$1.focus()", editor_widget)
    end

    --
    -- report error
    --

    if editor_status_text then
        show_error('Error: ' .. editor_status_text)
        editor_status_text = nil
        return
    end

    --
    -- finish setting up editor state
    --

    editor_folder_name, editor_file_name = folder_name, file_name
    editor_status_text = ':  <span class="filename">' .. file_name .. '</span> <span style="white-space: nowrap;">in folder</span> <span class="filename">' .. folder_name .. '</span>'
    editor_file_deleted, editor_file_created = false, false

    edit_show_status()

    if create_file then
        editor_file_created = true
        editor_changed = 1
        edit_save()
        JavaScript("$1.execCommand('selectAll')", editor_widget)
        return (editor_changed == 0)
    end

end

--
-- edit_save
--

function edit_save()

    if editor_saving or editor_changed < 1 then return end
    if not (editor_folder_name or editor_file_name) then return end

    local file_text
    JavaScript("$2=$1.getValue()", editor_widget, file_text)

    editor_mutex:lock()
    editor_saving = true

    local password = folder_password(editor_folder_name)
    local show_error_from_request = nil
    while true do

        show_status('Saving' .. editor_status_text)

        local res, err = call_server {
            op = 'save_file',
            folder = editor_folder_name,
            file = editor_file_name,
            source = file_text,
            password = password,
        }

        if err and err:index("password") then
            password = folder_password(editor_folder_name, "ask", show_error_from_request and err)
            if password then
                show_error_from_request = true
                continue
            end
            show_error(err .. '--' .. editor_status_text:sub(2) .. " was <u>NOT</u> saved!")
        end

        if not err then
            if file_text == "" then
                show_status('<u>FILE DELETED</u>' .. editor_status_text)
                refresh_folder(editor_folder_name)
                refresh_recents(editor_folder_name, editor_file_name, true)
                editor_file_deleted = true
            else
                edit_show_status()
                if editor_file_deleted or editor_file_created then
                    refresh_folder(editor_folder_name)
                    if editor_file_deleted then
                        refresh_recents(editor_folder_name, editor_file_name)
                    end
                    editor_file_deleted = false
                    editor_file_created = false
                end
            end
            JavaScript("$1.focus()", editor_widget)
        end

        editor_changed = 0
        break
    end

    editor_saving = false
    editor_mutex:unlock()

end

--
-- edit_show_status
--

function edit_show_status()

    if editor_status_text then
        show_status('Editing' .. editor_status_text)
    end

end

--
-- edit_get_name
--

function edit_get_name()

    return editor_folder_name, editor_file_name

end

--
-- main
--

local editor_html, err = document.load_html("editor.css", "editor.html")
if err then show_error(err) return end

local editor_section = document:getElementById("editor-section")
editor_section.innerHTML = editor_html.body.innerHTML

document:resizeCallback(function(w,h)
    local status = document:getElementById("status-section")
    h = h - status.offsetHeight
    h = tostring(h) .. 'px'
    editor_section.style.height = h
end)

editor_focus = function()
    if editor_widget then
        edit_show_status()
        JavaScript("$1.focus()", editor_widget)
    end
end

return editor_section
