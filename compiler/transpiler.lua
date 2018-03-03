
local jspfx = package.JavaScript and "Loulabelle*" or ""
local Parser = require(jspfx.."parser")
local Emitter = require(jspfx.."emitter")

return function(source_name, source_text, source_options)

    if source_options then
        assert(type(source_options) == "table")
        if source_options.version then
            return "1.0", 1.0
        end
    end
    assert(type(source_name) == "string")
    assert(type(source_text) == "string")

    local result
    local tree, err = Parser.parse(source_text, source_name)
    if not err then

        source_options = source_options or {}
        tree.jsobject = source_options.jsobject
        tree.debug = source_options.debug == nil and true or source_options.debug
        tree.JavaScript = source_options.JavaScript == nil and true or source_options.JavaScript
        tree.globals = source_options.globals == nil and true or source_options.globals

        result, err = Emitter.generate(tree)
    end

    if (not err) and source_options.env then

        local idx1 = result:index("function*func")
        local idx2 = result:rindex("}")
        if idx1 and idx2 then

            result = result:sub(idx1, idx2)
            JavaScript("try{var f=Function('return '+$1)()}catch(e){$2=e.toString()}", result, err)
            if not err then
                JavaScript("[f.self,f.env,f.file,f.line]=[f,$1,$2,1]", source_options.env, source_name)
                JavaScript("$1=f", result)
            end

        else
            result = nil
            err = "Internal error in compiler output"
        end
    end

    return result, err

end
