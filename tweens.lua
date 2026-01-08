--@name Tweens
--@author AstricUnion
--@shared


local TWEENS = {}

---@enum PROPERTY
PROPERTY = {
    NONE = {
        function() end,
        function() end
    },
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
    SCALE = {
        function(x) return x:getScale() end,
        function(x, set) x:setScale(set) end
    },
    ANGULARVELOCITY = {
        function(x) return x:getAngleVelocity() end,
        function(x, set) x:setAngleVelocity(set) end
    },
    -- Only with holograms!
    LOCALANGULARVELOCITY = {
        function(x) return x.angular end,
        function(x, set)
            if !x.angular then x.angular = Vector() end
            x:setLocalAngularVelocity(set)
            x.angular = set
        end
    },
    VELOCITY = {
        function(x) return x:getVelocity() end,
        function(x, set) x:setVelocity(set) end
    },
    ADDVELOCITY = {
        function(x) return x:getVelocity() end,
        function(x, set) x:addVelocity(set) end
    }
}


---Param class
---@class Param
---@field duration number Duration for parameter
---@field starttime number Start time for parameter
---@field object Entity Object for parameter
---@field to any Total for property
---@field delta any Delta of position for property
---@field ease function Function to ease
---@field callback function Callback for end of parameter
---@field process_callback function Callback for process of parameter
---@field get function Function to get progress
---@field set function Function to set progress
Param = {}

---Create new parameter
---@param duration number | table
---@param object Entity
---@param property PROPERTY
---@param to any | fun(): any
---@param ease fun(fraction: number): number
---@param callback? fun(tween: Tween)
---@param process_callback? fun(tween: Tween, fraction: number)
---@return Param
function Param:new(duration, object, property, to, ease, callback, process_callback)
    local starttime = 0
    if istable(duration) then
        starttime = duration[1]
        duration = duration[2] - starttime
    end
    return setmetatable(
        {
            duration = duration,
            starttime = starttime,
            object = object,
            to = to,
            delta = nil,
            ease = ease or function(x) return x end,
            callback = callback,
            process_callback = process_callback,
            get = property[1],
            set = property[2]
        },
        Param
    )
end


---Fraction class. Replace of fractional timers, just an empty parameter
---@class Fraction: Param
Fraction = {}


---Create new fraction
---@param duration number
---@param ease? fun(fraction: number)
---@param callback? fun(tween: Tween)
---@param process_callback? fun(tween: Tween, fraction: number)
---@return Fraction
function Fraction:new(duration, ease, callback, process_callback)
    local starttime = 0
    if istable(duration) then
        starttime = duration[1]
        duration = duration[2] - starttime
    end
    return setmetatable(
        {
            duration = duration,
            starttime = starttime,
            object = nil,
            to = nil,
            delta = nil,
            ease = ease or function(x) return x end,
            callback = callback,
            process_callback = process_callback,
            get = nil,
            set = nil
        },
        Fraction
    )
end

setmetatable(Fraction, {__index = Param})



---Tween class
---@class Tween
---@field parameters table
---@field paused boolean
---@field loop boolean
---@field thread thread
Tween = {}
Tween.__index = Tween


---Initialize new tween
function Tween:new()
    return setmetatable(
        {
            parameters = {},
            paused = true,
            loop = false,
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
---@param callback? function(tween: Tween) Time to sleep
function Tween:sleep(wait, callback)
    table.insert(self.parameters, {sleep = wait, callback = callback})
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


---Set tween to loop
---@param state boolean
function Tween:setLoop(state)
    self.loop = state
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
    local fraction = math.clamp((progress - param.starttime) / param.duration, 0, 1)
    local smoothed = math.round(param.ease(fraction), 3)
    if param.object then
        local pos = param.get(param.object)
        local to = isfunction(param.to) and param.to() or param.to
        local initial
        if param.delta then
            initial = (pos - param.delta)
        else
            initial = pos
        end
        local pos_smoothed = (to - initial) * smoothed
        param.set(param.object, initial + pos_smoothed)
        param.delta = pos_smoothed
    end
    return smoothed
end


---Process tween. this function is a coroutine
function Tween:process()
    local loop = true
    while loop do
        for _, params in ipairs(self.parameters) do
            if params.sleep then
                coroutine.wait(params.sleep)
                if params.callback then params.callback(self) end
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
                    if progress < param.starttime then continue end
                    local smoothed = paramProgress(param, progress)
                    if param.process_callback then param.process_callback(self, smoothed) end
                    if smoothed >= 1 then
                        table.insert(finished, i)
                        param.delta = Vector()
                        if param.callback then param.callback(self) end
                    end
                end

                if #finished == #params then
                    break
                end
            end
        end
        if !self.loop then return end
    end
end


hook.add("Think", "TweensProcess", function()
    for _, v in ipairs(TWEENS) do
        if v:isPaused() then continue end
        if !v:isValid() then v:remove() continue end
        coroutine.resume(v.thread, v)
    end
end)

