
local self = {}

JavaScript("yield*$L.require_js('https://cdnjs.cloudflare.com/ajax/libs/handlebars.js/4.0.11/handlebars.min.js')")
local handlebars
JavaScript("$1=Handlebars.noConflict()", handlebars)

self.compile = function(template, options)
    ::update_stack_frame::
    JavaScript("var html=yield*$L.checkstring($1,1)", template)
    options = options and coroutine.jsconvert(nil, options)
    JavaScript("var fn=$1.compile(html,$2)", handlebars, options)
    return function(context)
        ::update_stack_frame::
        context = context and coroutine.jsconvert(nil, context)
        JavaScript("var res,err")
        JavaScript("try{res=fn($1)}", context)
        JavaScript("catch(e){err='Handlebars: '+e.toString()}")
        JavaScript("return[res,err]")
    end
end

return self
