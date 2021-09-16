import 'CoreLibs/timer'
import 'CoreLibs/object'

playdate.display.setRefreshRate(20)
local gfx <const> = playdate.graphics

-- local references
local Timers_update = playdate.timer.updateTimers

-------------------------------------
--parent thread object

class('Action').extends()

function Action:launch()
    while not self.isFinished do
        coroutine.yield()
        self:update()
    end
end

function Action:update()
    --empty in case an action doesn't need one
end

-------------------------------------

class('WaitAction').extends(Action)

function WaitAction:init(time)
    self.lifetimer = playdate.timer.new(time*1000, function ()
        self.isFinished = true
    end)
    self.isFinished = false
end

function wait(time)
    local action = WaitAction(time)
    action:launch()
end

-------------------------------------

--displays text for a certain time
function displayText(text, time, x, y)
    local action = coroutine.create(function (text, time, x, y)
        coroutine.yield()
        local lifetimer = playdate.timer.new(time*1000)
        while lifetimer.timeLeft > 0 do
            gfx.setColor(gfx.kColorBlack)
            gfx.drawText(text, x, y)
            coroutine.yield()
        end
    end)
    table.insert(threadStack, action)
    coroutine.resume(action, text, time, x, y)
end

-------------------------------------

function testScene(x, y)
    wait(1)
    displayText("testing displayText", 3.0, x, y)
    wait(3.5)
    displayText("now, second displayText", 3.0, x, y)
    wait(3.5)
    displayText("why does this flicker?", 3.0, x, y)
end

threadStack = {}

local sceneA = coroutine.create(testScene)
coroutine.resume(sceneA, 10, 10)
table.insert(threadStack, sceneA)

local sceneB = coroutine.create(testScene)
coroutine.resume(sceneB, 10, 30)
table.insert(threadStack, sceneB)


function playdate.update()
    Timers_update()
    gfx.clear()

    --update threads in threadStack and remove when dead
    for i,c in ipairs(threadStack) do
        if coroutine.status(c) == 'dead' then
            table.remove(threadStack, i)
        else
            local r, m = coroutine.resume(c)
            if not r then
                print("Coroutine Error:", m)
            end
        end
    end
end