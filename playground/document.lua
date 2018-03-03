
local self = {}

local priv = {}

-- convert javascript value (including html objects) to lua value

priv.make_value = function(result)

    result = result[1]
    JavaScript("if($1 instanceof Document){", result)
    JavaScript(     "$1=$2}", result, (setmetatable({dom_elem=result}, priv.html_doc_mt)))
    JavaScript("else if($1 instanceof Node||$1 instanceof Element||$1 instanceof CSSStyleDeclaration||$1 instanceof DOMStringMap){", result)
    JavaScript(     "$1=$2}", result, (setmetatable({dom_elem=result}, priv.html_elem_mt)))
    JavaScript("else if(typeof $1==='function'&&$1.luacallback){$1=$1.luacallback}", result)
    JavaScript("else if(typeof $1==='object'||typeof $1==='function'){$1=undefined}", result)
    return result

end

-- generate event callback function

priv.make_callback = function(callback_function)

    local new_func = coroutine.jscallback(
        function(...)
            local ev = ...
            JavaScript("if($1 instanceof Event){", ev)
                local ev2 = {}
                local key, value
                JavaScript("for(var k in $1){", ev)
                JavaScript(     "if(k===null||k===undefined)continue")
                JavaScript(     "var v=$1[k]", ev)
                JavaScript(     "if(v===null)v=undefined")
                JavaScript(     "[$1,$2]=[k,v]", key, value)
                                ev2[key] = priv.make_value { value, true }
                JavaScript("}")
                do return callback_function(ev2, select(2, ...)) end
            JavaScript("}")
            return callback_function(...)
        end)
    ::update_stack_frame::
    JavaScript("$1.luacallback=$2", new_func, callback_function)
    return new_func

end

-- HTML Collection

function priv.html_coll_index(coll, key_name)
    local key_index = tonumber(key_name)
    local dom_elem
    if key_index then
        JavaScript("$3=$1.item($2)", coll.collection, key_index - 1, dom_elem)
    else
        JavaScript("$3=$1.namedItem($2)", coll.collection, key_name, dom_elem)
    end
    JavaScript("if(!$1)return[undefined]", dom_elem)
    return setmetatable({dom_elem=dom_elem}, priv.html_elem_mt)
end

function priv.html_coll_length(coll)
    JavaScript("return[$1.length]", coll.collection)
end

priv.html_coll_mt = {
    __index = priv.html_coll_index,
    __len = priv.html_coll_length,
}

-- HTML Attributes

function priv.html_attr_index(attr, key)
    assert(type(key) == 'string')
    JavaScript("var r=$1.getAttribute($2)", attr.dom_elem, key)
    JavaScript("if(r===null)r=undefined")
    JavaScript("return[r]")
end

function priv.html_attr_newindex(attr, key, value)
    assert(type(key) == 'string')
    if value then
        assert(type(value) == 'string')
        JavaScript("$1.setAttribute($2,$3)", attr.dom_elem, key, value)
    else
        JavaScript("$1.removeAttribute($2)", attr.dom_elem, key)
    end
end

function priv.html_attr_length(attr)
    JavaScript("return[$1.length]", attr.dom_attr)
end

function priv.html_attr_pairs(attr)
    local dom_attr = attr.dom_attr
    local i, n = 0
    JavaScript("$2=$1.length", dom_attr, n)
    return function()
        local k, v
        if i < n then
            JavaScript("try{")
            JavaScript(     "var r=$1.item($2)", dom_attr, i)
            JavaScript(     "if(typeof r.name==='string')$1=r.name", k)
            JavaScript(     "if(typeof r.value==='string')$1=r.value", v)
            JavaScript("}catch(e){")
                            k = nil
            JavaScript("}")
            i = i + 1
        end
        return k, v
    end
end

priv.html_attr_mt = {
    __index = priv.html_attr_index,
    __newindex = priv.html_attr_newindex,
    __len = priv.html_attr_length,
    __pairs = priv.html_attr_pairs
}

-- HTML Element

function priv.html_elem_index(elem, key_name)
    local result = getmetatable(elem)[key_name]
    if result then return result end
    JavaScript("$3=$1[$2]", elem.dom_elem, key_name, result)
    if key_name == "attributes" then
        result = setmetatable({dom_elem=elem.dom_elem, dom_attr=result}, priv.html_attr_mt)
        rawset(elem, key_name, result)
        return result
    end
    return priv.make_value{result,true} -- pass js object in table
end

function priv.html_elem_newindex(elem, key_name, value)
    if type(value) == 'function' then value = priv.make_callback(value) end
    JavaScript("$1[$2]=$3", elem.dom_elem, key_name, value)
end

function priv.html_elem_eq(elem1, elem2)
    JavaScript("return[$1===$2]", elem1.dom_elem, elem2.dom_elem)
end

function priv.html_elem_tostring(elem)
    JavaScript("return[$1.toString()]", elem.dom_elem)
end

function priv.html_elem_log(elem)
    JavaScript("console.log($1)", elem.dom_elem)
end

function priv.html_elem_focus(elem)
    JavaScript("$1.focus()", elem.dom_elem)
end

function priv.html_elem_click(elem)
    JavaScript("$1.click()", elem.dom_elem)
end

function priv.getElementsByClassName(elem, classes)
    JavaScript("$2=$1.getElementsByClassName($2)", elem.dom_elem, classes)
    return setmetatable({collection=classes}, priv.html_coll_mt)
end

function priv.getElementsByTagName(elem, tag)
    local children
    JavaScript("$3=$1.getElementsByTagName($2)", elem.dom_elem, tag, children)
    return setmetatable({collection=children}, priv.html_coll_mt)
end

function priv.childNodes(elem)
    local children
    JavaScript("$2=$1.childNodes", elem.dom_elem, children)
    return setmetatable({collection=children}, priv.html_coll_mt)
end

function priv.appendChild(elem, child)
    local dom_elem
    JavaScript("$3=$1.appendChild($2)", elem.dom_elem, child.dom_elem, dom_elem)
    return setmetatable({dom_elem=dom_elem}, priv.html_elem_mt)
end

function priv.insertBefore(elem, child, ref)
    local dom_elem
    JavaScript("$4=$1.insertBefore($2,$3||null)", elem.dom_elem, child.dom_elem, ref and ref.dom_elem, dom_elem)
    return setmetatable({dom_elem=dom_elem}, priv.html_elem_mt)
end

function priv.getComputedStyle(elem, psuedo_elem)
    local style
    if psuedo_elem then assert(type(psuedo_elem) == 'string') end
    JavaScript("$1=window.getComputedStyle($2,$3||null)", style, elem.dom_elem, psuedo_elem)
    return (setmetatable({dom_elem=style}, priv.html_elem_mt))
end



--[[function priv.observe(elem,func,flags)

    local funcs = {}

    local function callback(records,instance)
        JavaScript("console.log($1)", records)
    end

    local observer = priv.mutation_observer
    if not observer then
        JavaScript("$1=new MutationObserver($2)",
            observer, (coroutine.jscallback(callback)))
        priv.mutation_observer = observer
    end

    flags = coroutine.jsconvert(nil, flags or { attributes=true })
    JavaScript("$1.observe($2,$3)", observer, elem.dom_elem, flags)
    elem:log()

end]]

priv.html_elem_mt = {
    __index = priv.html_elem_index,
    __newindex = priv.html_elem_newindex,
    __eq = priv.html_elem_eq,
    __tostring = priv.html_elem_tostring,
    log = priv.html_elem_log,
    print = priv.html_elem_log,
    focus = priv.html_elem_focus,
    click = priv.html_elem_click,
    getElementsByClassName = priv.getElementsByClassName,
    getElementsByTagName = priv.getElementsByTagName,
    childNodes = priv.childNodes,
    appendChild = priv.appendChild,
    insertBefore = priv.insertBefore,
    getComputedStyle = priv.getComputedStyle,
    --observe = priv.observe,
}

-- HTML Document

function priv.html_doc_index(doc, key_name)
    return self[key_name] or priv.html_elem_index(doc, key_name)
end

priv.html_doc_mt = {}
for k,v in pairs(priv.html_elem_mt) do
    priv.html_doc_mt[k] = v
end

priv.html_doc_mt.__index = priv.html_doc_index

self.getElementById = function(elem, id)
    assert(elem and id)
    local dom_elem = elem.dom_elem
    assert(dom_elem)
    JavaScript("$1=$1.getElementById($2)", dom_elem, id)
    JavaScript("if(!($1 instanceof Node))return[undefined]", dom_elem)
    return setmetatable({dom_elem=dom_elem}, priv.html_elem_mt)
end

self.createElement = function(elem, tag)
    assert(elem and tag)
    local dom_elem = elem.dom_elem
    assert(dom_elem)
    JavaScript("$1=$1.createElement($2)", dom_elem, tag)
    JavaScript("if(!($1 instanceof Node))return[undefined]", dom_elem)
    return setmetatable({dom_elem=dom_elem}, priv.html_elem_mt)
end

self.fromElement = function(elem, dom_elem)
    assert(elem and dom_elem)
    JavaScript("if($1 instanceof Document||$1 instanceof Node||$1 instanceof Element){", dom_elem)
        do return setmetatable({dom_elem=dom_elem}, priv.html_doc_mt) end
    JavaScript("}")
    return nil
end

self.resizeCallback = function(elem, callback, enable)
    assert(elem and callback)

    if callback == true then

        local w, h
        JavaScript("[$1,$2]=[window.innerWidth,window.innerHeight]", w, h)
        for i = 1, #priv.resize_callbacks do
            callback = priv.resize_callbacks[i]
            callback(w,h)
        end

    elseif enable == false then

        if priv.resize_callbacks then
            for i=1,#priv.resize_callbacks do
                if priv.resize_callbacks[i] == callback then
                    table.remove(priv.resize_callbacks, i)
                    break
                end
            end
        end

    else

        local function actual_callback(event)
            local w, h
            JavaScript("[$2,$3]=[$1.target.innerWidth,$1.target.innerHeight]", event, w, h)
            for i=1,#priv.resize_callbacks do
                priv.resize_callbacks[i](w, h)
            end
        end
        if not priv.resize_callbacks then
            priv.resize_callbacks = {}
            JavaScript("window.addEventListener('resize',$1)",
                (coroutine.jscallback(actual_callback)))
        end

        priv.resize_callbacks[#priv.resize_callbacks+1] = callback
        local w, h
        JavaScript("[$1,$2]=[window.innerWidth,window.innerHeight]", w, h)
        callback(w,h)

    end
end

--
-- load external html page
--

self.load_html = function(...)
    for i = 1, select('#', ...) do
        local url = select(i, ...)
        if url:sub(-4,-1):lower() == '.css' then
            JavaScript("yield*$L.require_css($1)", url)
        else
            local dom_elem
            JavaScript("var status,co=$L.co")
            JavaScript("var xhr=new XMLHttpRequest()")
            JavaScript("xhr.onloadend=function(){status=xhr.status;co.resume()};")
            JavaScript("xhr.open('GET',$1)", url)
            JavaScript("xhr.setRequestHeader('Cache-Control','no-cache')")
            JavaScript("xhr.responseType='document'")
            JavaScript("xhr.send()")
            JavaScript("yield*$L.cosuspend()")
            JavaScript("if(status!==200)return[undefined,status]")
            JavaScript("$1=xhr.response", dom_elem)
            JavaScript("if(!($1 instanceof HTMLDocument))return[undefined,418]", dom_elem)
            return setmetatable({dom_elem=dom_elem}, priv.html_doc_mt)
        end
    end
    return nil, 418
end

--
-- load external data
--

self.load_form = function(url, form)
    JavaScript("var data")
    if form then
        JavaScript("data=new FormData()")
        for k,v in pairs(form) do
            JavaScript("data.append($1,$2)", k, v)
        end
    end
    JavaScript("var status,co=$L.co")
    JavaScript("var xhr=new XMLHttpRequest()")
    JavaScript("xhr.onloadend=function(){status=xhr.status;co.resume()};")
    JavaScript("xhr.open('POST',$1)", url)
    JavaScript("xhr.send(data)")
    JavaScript("yield*$L.cosuspend()")
    JavaScript("if(status!==200)return[undefined,status===0?999:status]")
    JavaScript("if(typeof xhr.response!=='string')return[undefined,418]", dom_elem)
    JavaScript("return[xhr.response]")
end

--
-- convert JSON data to table
--

self.parse_json = function(data)
    JavaScript("if(typeof $1==='string'){try{$1=JSON.parse($1)}catch(e){$1=undefined}}", data)
    JavaScript("if(typeof $1!=='object'){return[undefined]}", data)
    return coroutine.jsconvert(data, {})
end

--
-- create document from string
--

self.parseFromString = function(html)
    local dom_doc
    JavaScript("$2=(new DOMParser()).parseFromString($1,'text/html')", html, dom_doc)
    return setmetatable({dom_elem=dom_doc}, priv.html_doc_mt)
end

--
-- return a table that accesses the main document
--

local dom_doc
JavaScript("$1=document", dom_doc)
return setmetatable({dom_elem=dom_doc}, priv.html_doc_mt)
