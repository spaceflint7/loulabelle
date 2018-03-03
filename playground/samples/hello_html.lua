
local document = require "/document"


-- load a file from the current folder as a string,
-- parse it as a new DOM document, and embed it

local loaded_text = io.load("hello_html_doc")
local loaded_document = document.parseFromString(loaded_text)

document.body.innerHTML = loaded_document.body.innerHTML


-- install an onchange event handler on the input box,
-- which updates the contents of the output span

document:getElementById("input").onchange =

    function(event)

        document:getElementById("output").innerHTML =
            "Nice to meet you, " .. event.target.value .. "!"
    end


-- install an onclick event handler on the close button,
-- which wakes up the main coroutine

local main_co = coroutine.running()

document:getElementById("close").onclick =

    function() coroutine.resume(main_co) end


-- suspend the main coroutine.  when it is woken up
-- (by the onclick event handler), the program finishes

print 'Waiting for button click'
coroutine.suspend()
print 'Done'
