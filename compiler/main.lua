
local ok, transpiler = pcall(function() return require("transpiler") end)
if not ok then
    local idx = arg[0]:reverse():find('/', 1, true) or 0
    package.path = arg[0]:sub(1, -idx) .. "?.lua;" .. (package.path or "")
    transpiler = require("transpiler")
end

local pgmname = arg[0] or "Loulabelle"

local function usage()
    local version = transpiler(nil, nil, {version=true})
    print ("Loulabelle, Lua to JavaScript compiler, version " .. version)
    print ("usage: " .. pgmname .. " [-h] [-o] [-J] [-L var] [-n chunkname] inputfile")
    print ("-h: display usage")
    print ("-o: optimize function calls and turn off call stack")
    print ("-G: disallow assignment to globals without table reference")
    print ("-J: disallow JavaScript statements")
    print ("-A: disallow assume keywords")
    print ("-L: set object name for JavaScript (default $lua)")
    print ("-n: set chunk name (default same as inputfile argument)")
    return 1
end

local debug, jsallow, globals, assumes = true, true, true, true
local jsobject, chunkname
local i = 1
while true do
    local s = arg[i]
    if not s or s:sub(1,1) ~= '-' then break end
    if s == '-o' then
        debug = false
        table.remove(arg, i)
    elseif s == '-G' then
        globals = false
        table.remove(arg, i)
    elseif s == '-J' then
        jsallow = false
        table.remove(arg, i)
    elseif s == '-A' then
        assumes = false
        table.remove(arg, i)
    elseif s == '-L' then
        table.remove(arg, i)
        jsobject = arg[i]
        if not jsobject then return usage() end
        table.remove(arg, i)
    elseif s == '-n' then
        table.remove(arg, i)
        chunkname = arg[i]
        if not chunkname then return usage() end
        table.remove(arg, i)
    else return usage() end
end

local infile, filename
if #arg == 0 then
    infile = io.stdin
    filename = "(stdin)"
elseif #arg <= 1 then
    filename = arg[i]
    infile = assert(io.open(arg[i], "r"))
    i = i + 1
else return usage() end

if not chunkname then
    local idx = filename:reverse():find('/', 1, true) or 0
    chunkname = filename:sub(-idx + 1)
end

local source = infile:read("*all")
local javascript, errmsg = transpiler(
    chunkname, source, {
        debug = debug,
        jsobject = jsobject,
        globals = globals,
        assumes = assumes,
        JavaScript = jsallow
    })
if errmsg then
    io.stderr:write(filename..': '..errmsg..'\n')
    os.exit(2)
end

print (javascript)

return 0
