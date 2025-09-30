--@name AstroBase (BASE FOR ALL BOTS, DON'T WORK)
--@author AstricUnion
--@shared

---Gets key direction of player.
---@param ply Player
---@param negative_key number See IN_KEY enum
---@param positive_key number See IN_KEY enum
---@return number from -1 to 1
local function getKeyDirection(ply, negative_key, positive_key)
    return (ply:keyDown(positive_key) and 1 or 0) - (ply:keyDown(negative_key) and 1 or 0)
end


if SERVER then
    --Hitbox class
    hitbox = {}


    ---Cube-formed hitbox
    ---@param pos Vector Position of hitbox
    ---@param angle Angle Angle of hitbox
    ---@param size Vector Size of hitbox
    ---@param freeze boolean? Make hitbox freezed, default false
    ---@param visible boolean? Make hitbox visible, default false
    ---@return Entity hitbox Hitbox entity
    function hitbox.cube(pos, angle, size, freeze, visible)
        local hitbox = prop.createCustom(
            pos,
            angle,
            {
                {
                    Vector(-size.x, -size.y, -size.z), Vector(size.x, -size.y, -size.z),
                    Vector(size.x, size.y, -size.z), Vector(-size.x, size.y, -size.z),
                    Vector(-size.x, -size.y, size.z), Vector(size.x, -size.y, size.z),
                    Vector(size.x, size.y, size.z), Vector(-size.x, size.y, size.z),
                },
            },
            freeze
        )
        if not visible then hitbox:setColor(Color(255, 255, 255, 0)) end
        return hitbox
    end


    ---Base class for Astro
    ---@class AstroBase
    AstroBase = {
        ---@type table
        states = nil,
        ---@type number
        state = nil,
        ---@type number
        health = nil,
        ---@type number
        maxhealth = nil,
        ---@type number
        speed = nil,
        ---@type number
        sprint = nil,
        ---@type Vector
        velocity = nil,
        ---@type number
        ratio = nil,
        ---@type Entity
        body = nil,
        ---@type PhysObj
        physobj = nil,
        ---@type Entity
        head = nil,
        ---@type Vehicle
        seat = nil,
        ---@type Player
        driver = nil
    }
    AstroBase.__index = AstroBase

    ---AstroBase constructor
    ---@param states table States of Astro (REQUIRE STATE Idle AND NotInUse)
    ---@param body Entity Body hitbox
    ---@param head Entity Head hitbox
    ---@param seat Vehicle Bot seat
    ---@param health number Health of bot
    ---@param speed? number Speed of bot, default 200
    ---@param sprint? number Sprint speed of bot, default 600
    ---@param ratio? number Velocity linear interpolation ratio of bot, default 0.05
    ---@return AstroBase astro Astro object
    function AstroBase:new(states, body, head, seat, health, speed, sprint, ratio)
        if !(states.NotInUse and states.Idle) then
            throw("States require a NotInUse and Idle")
        end
        local physobj = body:getPhysicsObject()
        physobj:setMass(1000)
        seat:setParent(body)
        seat:setColor(Color(0, 0, 0, 0))
        head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        head:setMass(100)
        head:setParent(body)
        local astro = setmetatable(
            {
                states = states,
                state = states.NotInUse,
                health = health,
                maxhealth = health,
                speed = speed or 200,
                sprint = sprint or 600,
                velocity = Vector(),
                ratio = ratio or 0.05,
                body = body,
                physobj = physobj,
                head = head,
                seat = seat,
                driver = nil
            },
            AstroBase
        )

        local id = body:entIndex()
        -- Driver defense, because driver can be killed (ONLY ADMIN)
        hook.add("EntityTakeDamage", "AstroDriverDefense" .. id, function(target)
            return target == astro.driver
        end)
        -- Driver enters
        hook.add("PlayerEnteredVehicle", "AstroEntered" .. id, function(ply, vehicle)
            astro:enter(ply, vehicle)
        end)
        -- Driver left
        hook.add("PlayerLeaveVehicle", "AstroLeft" .. id, function(ply, vehicle)
            astro:leave(ply, vehicle)
        end)
        -- On chip remove
        hook.add("Removed", "AstroRemoved" .. id, function()
            if astro.driver then astro.driver:setColor(Color(255, 255, 255, 255)) end
        end)
        return astro
    end


    ---Gets direction of the driver
    ---@return Vector? direction Returns direction Astro moving in
    function AstroBase:getDirection()
        if !self.driver then return end
        local eyeangles = self.driver:getEyeAngles():setR(0)
        local dir = Vector(
            getKeyDirection(self.driver, IN_KEY.BACK, IN_KEY.FORWARD),
            getKeyDirection(self.driver, IN_KEY.MOVERIGHT, IN_KEY.MOVELEFT),
            0
        ):getRotated(eyeangles)
        dir.z = math.clamp(
            dir.z + getKeyDirection(self.driver, IN_KEY.SPEED, IN_KEY.JUMP),
            -1,
            1
        )
        return dir
    end

    function AstroBase:think(active_callback)
        local frametime = game.getTickInterval()
        local driver = self.seat:getDriver()
        local gravity = self.physobj:isGravityEnabled()
        if isValid(driver) then
            self.driver = driver
            if gravity then self.physobj:enableGravity(false) end
            local dir = self:getDirection()
            local speed = driver:keyDown(IN_KEY.DUCK) and self.sprint or self.speed
            self.velocity = math.lerpVector(self.ratio, self.velocity, dir * speed * 100 * frametime)
            self.physobj:setVelocity(self.velocity)
            -- Code from Astro Striker by [Squidward Gaming] --
            local eyeangles = driver:getEyeAngles():setR(0)
            local ang = self.seat:worldToLocalAngles(eyeangles - self.body:getAngles())
            local angvel = ang:getQuaternion():getRotationVector() - self.body:getAngleVelocity() / 5
            self.physobj:addAngleVelocity(angvel)
            --------------------------------------------------- Thanks! :3
            self.head:setAngles(eyeangles)
            if active_callback then active_callback(driver) end
        else
            self.driver = nil
            if !gravity then self.physobj:enableGravity(true) end
        end
        self.seat:setAngles(Angle())
    end

    ---Eye trace for Astro
    ---@param filter? table | Entity Filter to trace (hitbox, seat and head are always there)
    ---@return table? TraceResult Result of the trace
    function AstroBase:eyeTrace(filter)
        if !isValid(self.driver) then return end
        local pos = self.driver:getEyePos()
        local ang = self.driver:getEyeAngles()
        filter = filter or {}
        table.add(filter, {self.body, self.head, self.seat})
        return trace.line(pos, pos + ang:getForward() * 16384, filter)
    end


    function AstroBase:enter(ply, seat)
        if self.seat == seat then
            self.state = self.states.Idle
            seat:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.NONE)
            ply:setColor(Color(255, 255, 255, 0))
            net.start("OnEnter")
            net.writeEntity(self.head)
            net.send(ply)
        end
    end


    function AstroBase:leave(ply, seat)
        if self.seat == seat then
            self.state = self.states.NotInUse
            seat:setCollisionGroup(COLLISION_GROUP.VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            ply:setColor(Color(255, 255, 255, 255))
            net.start("OnLeave")
            net.send(ply)
        end
    end


    function AstroBase:setState(state)
        self.state = state
    end

    function AstroBase:getState()
        return self.state
    end

    function AstroBase:isAlive()
        return self.health > 0
    end

    function AstroBase:damage(amount, callback)
        if not self:isAlive() then return end
        self.health = self.health - amount
        if not self:isAlive() then
            if callback then callback() end
            self.seat:ejectDriver()
            self.physobj:enableGravity(true)
            self.head:setParent(nil)
            self.head:setFrozen(false)
            self.head:setPos(self.head:getPos())
            self.head:setCollisionGroup(COLLISION_GROUP.NONE)
            self.head:setVelocity(Vector(
                math.rand(-500, 500),
                math.rand(-500, 500),
                math.rand(-500, 500)
            ))
            timer.create("deathExplosion", 0.2, 3, function()
                local eff = effect.create()
                eff:setOrigin(self.body:getPos())
                eff:setScale(0.01)
                eff:setMagnitude(0.01)
                eff:play("explosion")
                self.body:emitSound("weapons/underwater_explode3.wav")
            end)
            self.seat:remove()
        end
    end
else


end
