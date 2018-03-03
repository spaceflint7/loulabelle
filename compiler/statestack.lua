

local class = {}


function class.new()

    local self = { }
    for k,_ in pairs(class) do self[k] = class[k] end
    return self

end


function class:push()

    local n = self.n or 0
    local new_st = {}
    if n > 0 then
        local old_st = self[self.n]
        for k,v in pairs(old_st) do new_st[k] = v end
    end
    n = n + 1
    self[n] = new_st
    self.n = n

end


function class:pop()

    local n = self.n or 0
    if n > 0 then
        self[n] = nil
        n = n - 1
        self.n = n
    end

end


function class:set(k, v)

    local n = self.n or 0
    if n > 0 then self[n][k] = v end

end


function class:get(k)

    local n = self.n or 0
    if n > 0 then return self[n][k] else return nil end

end


function class:count()

    local n = self.n or 0
    if n > 0 then return #self[n] else return 0 end

end


return class
