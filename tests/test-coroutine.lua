
local comain=coroutine.running()

function myco(a, coself)
    print ('entered coroutine', coroutine.running())
    print ('resuming main', comain, coroutine.resume(comain))
    if not coself then coself = coroutine.running() end
    print ('resuming self', coself, coroutine.resume(coself))
    print ('status in coroutine', coroutine.status(comain), coroutine.status(coself))
    print ((coroutine.running()),'a='..tostring(a))
    local b=coroutine.yield(a+1,a+2)
    print ((coroutine.running()),'b='..tostring(b))
    local c,d=coroutine.yield(b+1,b+2)
    print ((coroutine.running()),'c='..tostring(c)..',d='..tostring(d))
    return c+1,c+2
end

print '-----create-----'

local co = coroutine.create(myco)
print(type(myco),type(co))
print('RUNNING',coroutine.running())
print('STATE',coroutine.status(co))
print((coroutine.running()),coroutine.resume(co, 10, co))
print ('status in main', coroutine.status(comain), coroutine.status(co))
print((coroutine.running()),coroutine.resume(co, 20))
print((coroutine.running()),coroutine.resume(co, 30, 40))
print ('status in main', coroutine.status(comain), coroutine.status(co))
print((coroutine.running()),coroutine.resume(co, 40))
print ('status in main', coroutine.status(comain), coroutine.status(co))

print '-----wrap-----'

local wr = coroutine.wrap(myco)
print(type(wr))
print(wr(100))
print(wr(200))
print(wr(300,400))

---
---
---

print '-----counter-----'

local counter=0

function test()
    local co, main = coroutine.running()
    if main then
        counter=counter+1
        return counter, main
    else
        while true do
            counter=counter+1
            coroutine.yield(counter, main)
        end
    end
end

print(test())
local test2 = coroutine.wrap(test)
print(test())
print(test2())
print(test())
print(test2())
print(test())
print(test2())

print '-----meta-----'

---
---
---

local co1 = coroutine.create(myco)
local co2 = coroutine.create(myco)
debug.setmetatable(co1, {__index=coroutine})
print (debug.getmetatable(co1), debug.getmetatable(co2))
print (co1:resume(10))
print (co2:resume(10))


---
--- multival resume
---


local function multiRet1() return 1, 2, 3 end
local function multiRet2() return 4, 5, 6 end

local co = coroutine.create(function(a, b, c)
    print ('#1', a, b, c)
    assert(a == 1 and b == 2 and c == 3)
    a, b, c = coroutine.yield()
    print ('#2', a, b, c)
    assert(a == 4 and b == 5 and c == 6)
end)

local ok = coroutine.resume(co, multiRet1())
if ok then ok = coroutine.resume(co, multiRet2()) end
if not ok then error ('MULTIVAL TEST FAIL') end


---
---
---

if coroutine.spawn then

    coroutine.sleep(1000)

    print '-----spawn-----'

    local function spawned()
        print 'spawn'
        coroutine.sleep(1000)
        print 'slept'
        print '-----ALL OK-----'
    end

    coroutine.spawn(spawned)

end
