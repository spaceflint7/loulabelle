
local self = {}

local function storage_table(jsobjname)
    local jsobj
    JavaScript("try{var $1=window[$2]}catch(e){$1=undefined}", jsobj, jsobjname)
    local mt = {}

    mt.__index = function(self, k)
        assert(getmetatable(self) == mt)
        assert(type(k)=='string')
        local v
        if jsobj then
            JavaScript("try{")
            JavaScript(     "var v=$1.getItem($2)", jsobj, k)
            JavaScript(     "if(typeof v==='string')$1=v", v)
            JavaScript("}catch(e){}")
        end
        return v
    end

    mt.__newindex = function(self, k, v)
        assert(getmetatable(self) == mt)
        assert(type(k)=='string')
        if v then assert(type(v)=='string') end
        local r = false
        if jsobj then
            JavaScript("try{")
            if v then
                JavaScript( "$1.setItem($2,$3)", jsobj, k, v)
            else
                JavaScript( "$1.removeItem($2)", jsobj, k)
            end
                            r = true
            JavaScript("}catch(e){}")
        end
        return r
    end

    mt.__pairs = function(self)
        assert(getmetatable(self) == mt)
        local i, n = 0
        JavaScript("$2=$1.length", jsobj, n)
        return function()
            local k, v
            if i < n then
                JavaScript("try{")
                JavaScript(     "$3=$1.key($2)", jsobj, i, k)
                JavaScript(     "var v=$1.getItem($2)", jsobj, k, v)
                JavaScript(     "if(typeof v==='string')$1=v", v)
                JavaScript("}catch(e){")
                                k = nil
                JavaScript("}")
                i = i + 1
            end
            return k, v
        end
    end

    return setmetatable({}, mt)
end

--
--
--

return setmetatable({}, { __index = function(t, k)
    local s
    if k == "local" or k == "localStorage" then
        s = storage_table("localStorage")
        if s then
            t["local"] = s
            t["localStorage"] = s
        end
    elseif k == "session" or k == "sessionStorage" then
        s = storage_table("sessionStorage")
        if s then
            t["session"] = s
            t["sessionStorage"] = s
        end
    end
    return s
end })
