
local document = require("document")
local handlebars = require("handlebars")

local finder_div, finder_folder_tmpl, finder_file_tmpl
local finder_input_div, finder_input_box
local finder_recent_tmpl, finder_recent_div

--
-- refresh_recents
--

local finder_recents = nil
local storage = nil -- different from folder_password storage!

function refresh_recents(folder_name, file_name, remove_entry)

    local modified = false

    --
    -- reload list of recent folders from previous use
    --

    if not finder_recents then

        if not storage then
            storage = require("storage")["local"]
        end

        finder_recents = {}

        local index = 1
        while true do
            local key = "recent_" .. string.format("%04d",index)
            local value = storage[key]
            if not value then break end
            finder_recents[index] = { path=value }
            index = index + 1
        end

        if index > 1 then modified = true end

    end

    --
    -- update list of recent folders
    --

    if folder_name and file_name then

        local path = folder_name .. "/" .. file_name

        for index = 2, #finder_recents do
            if finder_recents[index].path == path then
                table.remove(finder_recents, index)
                modified = true
                break
            end
        end

        if remove_entry then
            if finder_recents[1].path == path then
                table.remove(finder_recents, 1)
                modified = true
            end

        elseif #finder_recents == 0 or finder_recents[1].path ~= path then
            table.insert(finder_recents, 1, { path = path })
            modified = true
        end

        if modified then

            local key = "recent_" .. string.format("%04d", #finder_recents + 1)
            storage[key] = nil
            for index = 1, #finder_recents do
                local key = "recent_" .. string.format("%04d", index)
                storage[key] = finder_recents[index].path
            end
        end

    end

    --
    -- refresh list of recent folders
    --

    if modified then

        if #finder_recents == 0 then
            finder_recent_div.innerHTML = ""
        else

            local function click_recent(event)
                local elem = event.target
                local run_file = elem.className:startswith("finder-button-run-file")
                if elem.tagName:lower() ~= "div" then elem = elem.parentNode end
                if elem.tagName:lower() == "span" then elem = elem.parentNode end
                local path = elem.dataset.path
                local idx = path:index('/')
                if not idx then return end
                local folder_name = path:sub(1,idx-1)
                local file_name = path:sub(idx+1)
                if run_file then
                    if edit_save then edit_save() end
                    switch_view("console")
                    console_run(folder_name, file_name)
                else
                    switch_view("editor")
                    edit_file(folder_name, file_name)
                end
            end

            local function clear_recent(event)
                local index = 1
                while true do
                    local key = "recent_" .. string.format("%04d",index)
                    local value = storage[key]
                    if not value then break end
                    storage[key] = nil
                    index = index + 1
                end
                finder_recents = {}
                finder_recent_div.innerHTML = ""
            end

            local res, err = finder_recent_tmpl { recents = finder_recents }
            if err then show_error('Error in template: ' .. err) return end

            finder_recent_div.innerHTML = res

            local rows = finder_recent_div:getElementsByClassName("finder-row")
            for i = 1, #rows do rows[i].onclick = click_recent end

            finder_recent_div:getElementsByClassName("finder-button-clear-recent")[1].onclick = clear_recent

        end

    end

end

--
-- reload_folders
--

function reload_folders(event)

    local res, err = call_server {
        op = 'list_folders',
        folder = (event and event.target.value or "")
    }

    if not err then
        res.n = nil
        res, err = finder_folder_tmpl {folders=res}
        if err then err = 'Error in template: ' .. err end
    end

    if err then
        show_error(err)
    else

        finder_div.innerHTML = res

        local links = finder_div:getElementsByClassName("finder-row")
        for i = 1, #links do links[i].onclick = click_folder end

        links = finder_div:getElementsByClassName("finder-button-change-password")
        for i = 1, #links do
            links[i].style.display = "inline"
            links[i].onclick = folder_password
        end

    end

end

--
-- click_folder
--

function click_folder(event)

    local target_div = event.target
    if target_div.className:startswith("finder-button-") then return end
    if not target_div.className:startswith("finder-row") then
        target_div = target_div.parentNode
        if target_div.tagName:lower() == "span" then target_div = target_div.parentNode end
    end

    local images = target_div:getElementsByTagName("img")

    if target_div.dataset.folderOpen == "open" then

        target_div.dataset.folderOpen = ""
        images[1].style.display = "inline"
        images[2].style.display = "none"
        images[3].style.display = "none"
        images[4].style.display = "inline"

        target_div.nextElementSibling.innerHTML = ""

    else

        local folder_name = target_div.dataset.folderName
        local res, err = call_server {
            op = 'list_files',
            folder = folder_name,
        }

        if not err then
            res.n = nil
            res = { files = res, folder_name = folder_name }
            res, err = finder_file_tmpl (res)
            if err then err = 'Error in template: ' .. err end
        end

        if err then
            show_error(err)
        else

            target_div.dataset.folderOpen = "open"
            images[1].style.display = "none"
            images[2].style.display = "inline"
            images[3].style.display = "inline"
            images[3].onclick = make_new_file
            images[4].style.display = "none"

            local files_div = target_div.nextElementSibling
            files_div.innerHTML = res

            local links = files_div:getElementsByClassName("finder-row")
            for i = 1, #links do
                links[i].onclick = click_file
                if not mobile then
                    local span = links[i]:getElementsByClassName("filename")[1]
                    if span and #span.title > 10 then
                        span.style.fontSize = "100%"
                    end
                end
            end
        end

    end

end

--
-- refresh_folder
--

function refresh_folder(folder_name)

    local children = finder_div:childNodes()
    for i = 1, #children do
        local row = children[i]
        if row.tagName and row.tagName:lower() == "div"
                       and row.className:startswith("finder-row") then
            if row.dataset.folderName == folder_name then
                if row.dataset.folderOpen == "open" then
                    local event = { target = row }
                    click_folder(event) -- close folder
                    click_folder(event) -- reopen folder
                end
                break
            end
        end
    end

end

--
-- click_file
--

function click_file(event)

    local target_div = event.target
    local run_file = target_div.className:startswith("finder-button-run-file")
    if not target_div.className:startswith("finder-row") then
        target_div = target_div.parentNode
        if target_div.tagName:lower() == "span" then target_div = target_div.parentNode end
    end

    local folder_name = target_div.dataset.folderName
    local file_name = target_div.dataset.fileName
    if run_file then
        if edit_save then edit_save() end
        switch_view("console")
        console_run(folder_name, file_name)
    else
        refresh_recents(folder_name, file_name)
        switch_view("editor")
        edit_file(folder_name, file_name)
    end

end

--
-- make_new_folder
--

function make_new_folder(event)

    local folder_name = document:getElementById("new-folder-name")
    local password_field = document:getElementById("new-folder-password")
    local password2_field = document:getElementById("new-folder-password2")
    local folder_error = document:getElementById("new-folder-error")

    folder_name.value, folder_error.innerHTML = "", ""

    while true do
        password_field.value, password2_field.value = "", ""

        local modal, button = modal_dialog("new-folder-modal")
        if not button then
            modal.close()
            break
        end

        local new_folder = folder_name.value
        local new_password = password_field.value

        if password2_field.value ~= new_password then
            folder_error.innerHTML = "Password fields must be same"
            continue
        end

        local res, err = call_server {
            op = 'new_folder',
            folder = new_folder,
            password = new_password }
        if not err and (not res or not res.ok) then err = "Unknown error" end
        if err then
            folder_error.innerHTML = err
            continue
        end

        folder_password(new_folder, "set", new_password)
        modal.close()
        coroutine.spawn(reload_folders)
        break
    end

end

--
-- make_new_file
--

local make_new_file_in_folder

function make_new_file(event)

    if event.type == "blur" then
        event.type = "keydown"
        event.keyCode = 27
    end

    if event.type ~= "keydown" then

        --
        -- pop up new file name input box
        --

        local target_div = event.target
        if not target_div.className:startswith("finder-row") then
            target_div = target_div.parentNode
        end
        make_new_file_in_folder = target_div.dataset.folderName

        finder_input_div.style.display = "block"

        local files_div = target_div.nextElementSibling
        files_div:insertBefore(finder_input_div, files_div:childNodes()[1])

        finder_input_box.value = ""
        finder_input_box:focus()

    elseif event.keyCode == 13 then

        --
        -- enter key was pressed in the input box
        --

        local folder_name = make_new_file_in_folder
        local file_name = event.target.value

        if folder_name and folder_name ~= ""
            and file_name and file_name ~= "" then

            switch_view("editor")
            if edit_file(folder_name, file_name, true) then

                make_new_file_in_folder = nil
                finder_input_div.style.display = "none"
                refresh_recents(folder_name, file_name)
            end
        end

    elseif event.keyCode == 27 then

        --
        -- escape key was pressed, or input box lost focus
        --

        make_new_file_in_folder = nil
        finder_input_div.style.display = "none"

    end

end

--
-- folder_password
--

local storage = nil -- different from folder_recents storage!

function folder_password(folder, dlg, extra)

    if not storage then
        storage = require("storage")["session"]
    end

    if type(folder) == "table" and folder.target then
        -- first parameter is an event object
        folder = folder.target.parentNode.dataset.folderName
        if folder then dlg = "change" else return nil end
    end

    local key = "password_" .. folder

    if dlg == "set" then

        storage[key] = extra

    elseif dlg == "ask" then

        --
        -- ask password for folder
        --

        while modal_dialog_active do coroutine.sleep(1000) end

        document:getElementById("ask-password-folder-name").innerHTML = folder
        document:getElementById("ask-password-error").innerHTML = extra or ""

        local password_field = document:getElementById("ask-password-password")
        password_field.value = ""

        local modal, button = modal_dialog("ask-password-modal")
        modal.close()

        if not button then return nil end
        storage[key] = password_field.value

    elseif dlg == "change" then

        --
        -- change folder password
        --

        if modal_dialog_active then return end

        document:getElementById("change-password-folder-name").innerHTML = folder

        local password1_field = document:getElementById("change-password1")
        local password2_field = document:getElementById("change-password2")
        local password3_field = document:getElementById("change-password3")
        local error_field = document:getElementById("change-password-error")

        error_field.innerHTML = "", ""

        while true do
            password1_field.value, password2_field.value, password3_field.value = "", "", ""

            local modal, button = modal_dialog("change-password-modal")
            if not button then
                modal.close()
                break
            end

            local new_password = password2_field.value
            if new_password ~= password3_field.value then
                error_field.innerHTML = "Password fields must be same"
                continue
            end

            local res, err = call_server {
                op = 'change_password',
                folder = folder,
                password = password1_field.value,
                password2 = new_password }

            if res and res.ok == "ok" then
                storage[key] = new_password
                modal.close()
                break
            else
                error_field.innerHTML = err or "Unknown error"
            end
        end

    end

    return storage[key] or ""

end

--
-- read_file
--

function read_file(folder_name, file_name)

    local res, err = call_server {
        op = 'read_file',
        folder = folder_name,
        file = file_name
    }

    if err then return nil, err
    else return res.source_text end

end

--
-- main
--

return function ()

local finder_html, err = document.load_html("finder.css", "finder.html")
if err then show_error(err) return end
document:getElementById("finder-section").innerHTML = finder_html.body.innerHTML

local template_element = document:getElementById("finder-folder-template")
finder_folder_tmpl = handlebars.compile(template_element.innerHTML)
finder_div = template_element.parentElement

template_element = document:getElementById("finder-file-template")
finder_file_tmpl = handlebars.compile(template_element.innerHTML)

template_element = document:getElementById("finder-recent-template")
finder_recent_tmpl = handlebars.compile(template_element.innerHTML)
finder_recent_div = template_element.parentElement

document:getElementById("finder-button-new-folder").onclick = make_new_folder

finder_input_div = document:getElementById("finder-new-file-name")
finder_input_box = finder_input_div:getElementsByTagName("input")[1]
finder_input_box.onkeydown, finder_input_box.onblur = make_new_file, make_new_file

document:getElementById("finder-button-console").onclick =
    function()
        if edit_save then edit_save() end
        switch_view("console")
        if console_focus then console_focus() end
    end

if mobile then
    document:getElementById("status-run-button").onclick =
        function()
            if edit_save then
                edit_save()
                switch_view("console")
                back_button_switch_editor = true
                console_run(edit_get_name())
            end
        end
end

coroutine.spawn(reload_folders)
coroutine.spawn(refresh_recents)

end
