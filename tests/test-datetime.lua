
local function prt(...)
    local n = select('#', ...)
    for i = 1, n do
        local t = select(i, ...)
        if type(t) == "table" then
            print ("YYYY/MM/DD [YDAY,WDAY] HH:MM:SS [DST] = "
                .. tostring(t.year) .. "/" .. tostring(t.month) .. "/" .. tostring(t.day)
                .. " [" .. tostring(t.yday) .. "," .. tostring(t.wday) .. "] "
                .. tostring(t.hour) .. ":" .. tostring(t.min) .. ":" .. tostring(t.sec)
                .. " [" .. tostring(t.isdst) .. "]")
        elseif type(t) == "number" then
            print ("UNIX Time = " .. tostring(t))
        else
            print ("Date String = " .. t)
        end
    end
end

--
-- note, this test may fail in some timezones,
-- because Date() in Node.js does not handle timezones correctly
--

local time = (os.time { year = 1989, day = 0, month = 11, isdst = false })
local date = os.date("*t", 0)
prt(time,date)

local time = (os.time { year = 1989, day = 0, month = 1, isdst = false})
local date = os.date("*t", time)
prt(time,date)

print '-----ALL OK-----'
