--- === CMeters ===
---
---
---

local obj={}
obj.__index = obj

CircleMeterDeathSwitch = false
local CircleMeterEventLoop
local CaffeinateWatcher

-- Metadata
obj.name = "CMeters"
obj.version = "0.1"
obj.author = "Christian Fufezan <christian@fufezan.net>"
obj.homepage = ""
obj.license = ""
obj.scriptPath = nil

local cscreen = hs.screen.mainScreen()
local cres = cscreen:fullFrame()

obj.canvas = hs.canvas.new({
    x = 0,
    y = 0,
    w = 600,
    h = 800
}):show()

obj.canvas:level(hs.canvas.windowLevels.desktop) -- overlay) -- desktop) --
obj.interface = hs.network.primaryInterfaces()

obj.rings = {
    cpu_seconds = {
     radius = 150,
     startAngle = 0,
     endAngle = 180,
     meterType = 'cpu',
     refreshEvery = 'second',
     baseLineAlpha = 0.5,
     stepsToBaseLineAlpha = 5,
     minWidth = 3,
     maxWidth = 70,
     color = "#3288bd",
     center = {
         x = 200,
         y = 200
     },
     value_range = {
        min = 0,
        max = 100
     }
    },
    cpu_minutes = {
     radius = 100,
     startAngle = 0,
     endAngle = 360,
     meterType = 'cpu',
     refreshEvery = 'minute',
     baseLineAlpha = 0.2,
     stepsToBaseLineAlpha = 5,
     minWidth = 3,
     maxWidth = 70,
     color = "#fdae61",
     center = {
         x = 200,
         y = 200
     },
     value_range = {
        min = 0,
        max = 100
     }
    },
    cpu_hours = {
     radius = 50,
     startAngle = 0,
     endAngle = 360,
     meterType = 'cpu',
     refreshEvery = 'hour',
     baseLineAlpha = 0.2,
     stepsToBaseLineAlpha = 5,
     minWidth = 3,
     maxWidth = 70,
     color = "#d53e4f",
     center = {
         x = 200,
         y = 200
     },
     value_range = {
        min = 0,
        max = 100
     }
    },
    -- network_in = {
    --     radius = 100,
    --     startAngle = 0,
    --     endAngle = 180,
    --     meterType = 'network',
    --     meterTypeSubType = 'in',
    --     refreshEvery = 'second',
    --     baseLineAlpha = 0.5,
    --     stepsToBaseLineAlpha = 5,
    --     minWidth = 4,
    --     maxWidth = 40,
    --     color = "#3288bd",
    --     center = {
    --         x = 200,
    --         y = 520
    --     },
    --     value_range = { -- net in MB
    --        min = 0,
    --        max = 11
    --     }
    -- },
    -- network_out = {
    --     radius = 100,
    --     startAngle = 180,
    --     endAngle = 360,
    --     meterType = 'network',
    --     meterTypeSubType = 'out',
    --     refreshEvery = 'second',
    --     baseLineAlpha = 0.5,
    --     stepsToBaseLineAlpha = 5,
    --     minWidth = 4,
    --     maxWidth = 40,
    --     color = "#d53e4f",
    --     center = {
    --         x = 200,
    --         y = 520
    --     },
    --     value_range = { -- net in MB
    --        min = 0,
    --        max = 0.6
    --     },
    --     -- withShadow = true
    -- },
}


local function scriptPath()
    --https://stackoverflow.com/questions/6380820/get-containing-path-of-lua-file
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local function _streamCallBack(task, stdOut, stdErr)
    local stats = {}
    for k, v in string.gmatch(stdOut, "(%a+):([0-9.]+)") do
        stats[k] = tonumber(v)
    end
    obj:_updateRings(obj, stats)
    return true
end

local function _systemEvents(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        for name, ring in pairs(obj.rings) do
            ring.neverBeenDrawn = true
            for pos, ringElement in pairs(obj[name]) do
                obj.canvas[name .. pos].strokeColor.alpha = ring.baseLineAlpha
            end
        end
    end
end

function obj:_fadeRingeElements(self, name, current)
    local alphaStepSize = (1 - self.rings[name].baseLineAlpha) / self.rings[name].stepsToBaseLineAlpha
    local currentAlpha = self.rings[name].baseLineAlpha
    for pos = current + 60 - self.rings[name].stepsToBaseLineAlpha, current + 60 do
        self.canvas[name..(pos % 60)].strokeColor.alpha = currentAlpha
        currentAlpha = currentAlpha + alphaStepSize
    end
end


function obj:_prepareRing(self, name, ring)
    self[name] = {}
    ring.steps = 60
    if ring.refreshEvery == 'second' then
        ring.steps = 60
    elseif ring.refreshEvery == 'minute' then
        ring.steps = 60
    elseif ring.refreshEvery == 'hour' then
        ring.steps = 24
    else
        print('Dont understand refreshEvery on ring' .. name)
    end

    local stepSize = (ring.endAngle - ring.startAngle) / (ring.steps)
    local pos = 0
    local currentStartAngle = ring.startAngle
    local currentEndAngle = ring.startAngle + stepSize
    while (currentEndAngle <= ring.endAngle)
    do
        self[name][pos] = {
            startAngle = currentStartAngle,
            endAngle = currentEndAngle,
            value = 0,
            observations = 0
        }
        -- implicit pos to string format - thanks LUA
        currentStartAngle = currentStartAngle + stepSize
        currentEndAngle = currentEndAngle + stepSize
        pos = pos + 1
    end
end

function obj:_updateRings(self, stats)
    local currentSecond = stats['currentSecond']
    local currentMinute = stats['currentMinute']
    local currentHour = stats['currentHour']

    for name, ring in pairs(self.rings) do

        local width = 1
        local pos = 0
        local draw = false
        local value = 1

        if ring.meterType == 'cpu' then
            value = stats['cpu']
        elseif ring.meterType == 'network' then
            if ring.meterTypeSubType == 'in' then
                value = stats['netIn']
            else
                value = stats['netOut']
            end

        else
            print('Dont know metertype ' .. ring.meterType)
        end

        if ring.refreshEvery == 'second' then
            pos = currentSecond
            draw = true
        elseif ring.refreshEvery == 'minute' then
            pos = currentMinute
        elseif ring.refreshEvery == 'hour' then
            pos = currentHour
        end

        if currentSecond == 0 then
            if ring.refreshEvery == 'minute' then
                draw = true
            end
            if (ring.refreshEvery == 'hour' and currentMinute == 0) then
                pos = currentHour
                draw = true
            end
        end

        if ring.neverBeenDrawn == true then
            ring.neverBeenDrawn = false
            draw = true
            value = 1
        end

        self[name][pos].value = self[name][pos].value + value
        self[name][pos].observations = self[name][pos].observations + 1


        if draw == true then
            width = ring.minWidth + (ring.valueStepSize * self[name][pos].value / self[name][pos].observations)
            self.canvas[name .. pos].strokeWidth = width
            self[name][pos].value = 0
            self[name][pos].observations = 0
            self:_fadeRingeElements(self, name, pos)
        end
    end
end

local function wOtEvaThatIsGoodFor(exitCode, stdOut, StdErr)
end

local function _eventLoopFunction()
    -- adapted from asmagill
    -- https://github.com/Hammerspoon/hammerspoon/issues/1103
    if CircleMeterDeathSwitch == true then
        CircleMeterEventLoops:stop()
        CircleMeterEventLoops = nil
        CaffeinateWatcher:stop()
        CaffeinateWatcher = nil
        obj = nil
    else
        hs.task.new(
            '/usr/local/bin/python3',
            wOtEvaThatIsGoodFor,
            _streamCallBack,
            {obj.scriptPath .. 'ssm.py'}
        ):start()
    end
end


function obj:init()
    CaffeinateWatcher = hs.caffeinate.watcher.new(_systemEvents):start()

    for name, ring in pairs(obj.rings) do
        obj.rings[name].valueStepSize = (obj.rings[name].maxWidth - obj.rings[name].minWidth) / (obj.rings[name].value_range.max - obj.rings[name].value_range.min)
        obj.rings[name]['neverBeenDrawn'] = true
        obj:_prepareRing(obj, name, ring)
        -- obj.canvas:appendElements(
        --     {
        --         id = name .. 'label',
        --         type = "text",
        --         text = name,
        --         frame = {x='10%', y='10%', w=100, h = 50}
        --     })

        for pos, ringElement in pairs(obj[name]) do
            obj.canvas:appendElements(
                {
                    id = name .. pos,
                    type = "arc",
                    action = "stroke",
                    radius = ring.radius,
                    arcRadii = false,
                    strokeWidth = ring.minWidth,
                    strokeColor = {
                        hex = ring.color,
                        alpha = ring.baseLineAlpha
                    },
                    center = ring.center,
                    startAngle = ringElement.startAngle,
                    endAngle = ringElement.endAngle,
                })
        end
    end
    CircleMeterEventLoops = hs.timer.new(1, _eventLoopFunction)
    CircleMeterEventLoops:start()
    obj.scriptPath = scriptPath()

end

return obj
