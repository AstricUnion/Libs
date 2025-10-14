--@name Tweens
--@author AstricUnion
--@server


local TWEENS = {}

---@enum PROPERTY
PROPERTY = {
    POS = {
        function(x) return x:getPos() end,
        function(x, set) x:setPos(set) end
    },
    ANGLES = {
        function(x) return x:getAngles() end,
        function(x, set) x:setAngles(set) end
    },
    LOCALPOS = {
        function(x) return x:getLocalPos() end,
        function(x, set) x:setLocalPos(set) end
    },
    LOCALANGLES = {
        function(x) return x:getLocalAngles() end,
        function(x, set) x:setLocalAngles(set) end
    },
    COLOR = {
        function(x) return x:getColor() end,
        function(x, set) x:setColor(set) end
    },
    ANGULARVELOCITY = {
        function(x) return x:getAngleVelocity() end,
        function(x, set) x:setAngleVelocity(set) end
    },
    VELOCITY = {
        function(x) return x:getVelocity() end,
        function(x, set) x:setVelocity(set) end
    }
}


---Param class
---@class Param
---@field duration number Duration for parameter
---@field object Entity Object for parameter
---@field to any Total for property
---@field delta any Delta of position for property
---@field ease function Function to ease
---@field callback function Callback for parameter
---@field get function Function to get progress
---@field set function Function to set progress
Param = {}


---Create new parameter
---@param duration number
---@param object Entity
---@param property PROPERTY
---@param to any
---@param ease function(fraction: number): number
---@param callback? function(tween: Tween)
---@return Param
function Param:new(duration, object, property, to, ease, callback)
    return setmetatable(
        {
            duration = duration,
            object = object,
            to = to,
            delta = Vector(),
            ease = ease,
            callback = callback,
            get = property[1],
            set = property[2]
        },
        Param
    )
end


---Tween class
---@class Tween
Tween = {
    ---@type table
    parameters = nil,

    ---@type boolean
    paused = nil,

    ---@type thread
    thread = nil
}
Tween.__index = Tween


---Initialize new tween
function Tween:new()
    return setmetatable(
        {
            parameters = {},
            paused = true,
            thread = nil
        },
        Tween
    )
end


---Add new parameters to tween
---@param ... Param
function Tween:add(...)
    table.insert(self.parameters, {...})
end


---Add sleep to tween
---@param wait number Time to sleep
function Tween:sleep(wait)
    table.insert(self.parameters, {sleep = wait})
end


---Start tween
function Tween:start()
    if !self.thread then
        self.thread = coroutine.create(self.process)
        table.insert(TWEENS, self)
    end
    self.paused = false
end


---Pause tween
function Tween:pause()
    self.paused = true
end


---Remove tween from process
function Tween:remove()
    table.removeByValue(TWEENS, self)
    self.thread = nil
end


---Is tween valid
function Tween:isValid()
    return self.thread and coroutine.status(self.thread) ~= "dead"
end


---Is tween paused
function Tween:isPaused()
    return self.paused
end


---To progress an param
local function paramProgress(param, progress)
    local smoothed = math.round(param.ease(math.timeFraction(0, param.duration, progress)), 3)
    smoothed = math.clamp(smoothed, 0, 1)
    local pos = param.get(param.object)
    local initial = (pos - param.delta)
    local pos_smoothed = (param.to - initial) * smoothed
    param.set(param.object, initial + pos_smoothed)
    param.delta = pos_smoothed
    return smoothed
end


---Process tween. this function is a coroutine
function Tween:process()
    for _, params in ipairs(self.parameters) do
        if params.sleep then
            coroutine.wait(params.sleep)
            continue
        end
        local progress = 0
        local finished = {}
        while progress >= 0 do
            coroutine.yield()
            local tick = game.getTickInterval()
            progress = progress + tick
            for i, param in ipairs(params) do
                ---@cast param Param
                if table.hasValue(finished, i) then continue end
                local smoothed = paramProgress(param, progress)

                if smoothed >= 1 then
                    table.insert(finished, i)
                    if param.callback then param.callback(self) end
                end
            end

            if #finished == #params then
                break
            end
        end
    end
end


hook.add("Think", "TweensProcess", function()
    for _, v in ipairs(TWEENS) do
        if v:isPaused() then continue end
        if !v:isValid() then v:remove() continue end
        coroutine.resume(v.thread, v)
    end
end)

