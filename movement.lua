--@name Movement
--@author AstricUnion
--@server


---Gets key direction of player.
---@param ply Player
---@param negative_key IN_KEY See IN_KEY enum
---@param positive_key IN_KEY See IN_KEY enum
---@return number from -1 to 1
local function getKeyDirection(ply, negative_key, positive_key)
    return (ply:keyDown(positive_key) and 1 or 0) - (ply:keyDown(negative_key) and 1 or 0)
end

Movement = {}
Movement.__index = Movement

---Movement object. Implementing movement behaviour for bot.
---@param seat Entity Seat to use with bot, will be parented to hitbox
---@param hitbox Entity Hitbox to use with bot (collision model)
---@param speed number Bot maximum speed. Default 600
---@param sprint number Bot sprint maximum speed. Default 200
---@param duration number Bot stop speed. Default 0.05
---@return Movement object
function Movement:new(seat, hitbox, speed, sprint, duration)
    local physobj = hitbox:getPhysicsObject()
    physobj:setMass(1000)
    seat:setParent(hitbox)
    seat:setColor(Color(0, 0, 0, 0))
    local self = setmetatable(
        {
            speed = speed or 200,
            sprint = sprint or 600,
            velocity = Vector(),
            duration = duration or 0.05,
            hitbox = hitbox,
            physobj = physobj,
            seat = seat
        },
        Movement
    )
    return self
end


function Movement:getDirection(driver)
    local eyeangles = driver:getEyeAngles():setR(0)
    local dir = Vector(
        getKeyDirection(driver, IN_KEY.BACK, IN_KEY.FORWARD),
        getKeyDirection(driver, IN_KEY.MOVERIGHT, IN_KEY.MOVELEFT),
        0
    ):getRotated(eyeangles)
    dir.z = math.clamp(
        dir.z + getKeyDirection(driver, IN_KEY.SPEED, IN_KEY.JUMP),
        -1,
        1
    )
    return dir
end


---Think hook for Movement. Also can be used in Tick
function Movement:think(active_callback)
    local frametime = game.getTickInterval()
    local driver = self.seat:getDriver()
    if isValid(driver) then
        if self.physobj:isGravityEnabled() then
            self.physobj:enableGravity(false)
        end
        local dir = self:getDirection(driver)
        if not driver:keyDown(IN_KEY.DUCK) then
            self.velocity = math.lerpVector(self.duration, self.velocity, dir * self.speed * 100 * frametime)
        else
            self.velocity = math.lerpVector(self.duration, self.velocity, dir * self.sprint * 100 * frametime)
        end
        self.physobj:setVelocity(self.velocity)
        -- Code from Astro Striker by [Squidward Gaming] --
        local eyeangles = driver:getEyeAngles():setR(0)
        local ang = self.seat:worldToLocalAngles(eyeangles - self.hitbox:getAngles())
        ang = ang:getQuaternion():getRotationVector() - self.hitbox:getAngleVelocity() / 5
        self.physobj:addAngleVelocity(ang)
        --------------------------------------------------- Thanks! :3
        if active_callback then active_callback(driver) end
    else
        if not self.physobj:isGravityEnabled() then
            self.physobj:enableGravity(true)
        end
    end
    self.seat:setAngles(Angle())
end

