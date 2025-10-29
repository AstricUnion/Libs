--@name AstroBase
--@author AstricUnion
--@shared


-- Hooks --

-- SERVER
-- "AstroActivate(astro: AstroBase, ply: Player)"
-- "AstroDeactivate(astro: AstroBase, ply: Player)"
-- "AstroThink(astro: AstroBase, driver: Player)"
-- "AstroDamage(astro: AstroBase, amount: number)"
-- "AstroDeath(astro: AstroBase)"
-- "InputPressed(ply: Player, key: KEY)"
-- "InputReleased(ply: Player, key: KEY)"

-- CLIENT
-- "AstroEntered(pinPoint: Entity, body: Entity)"
-- "AstroLeft()"


-- Envirnoment variables
local WHITELIST = table.add({owner():getSteamID()}, WHITELIST or {})
local PROTECT = PROTECT ~= false and true or false



---Gets key direction of player.
---@param ply Player
---@param negative_key number See IN_KEY enum
---@param positive_key number See IN_KEY enum
---@return number from -1 to 1
local function getKeyDirection(ply, negative_key, positive_key)
    return (ply:keyDown(positive_key) and 1 or 0) - (ply:keyDown(negative_key) and 1 or 0)
end


if SERVER then
    ---Base class for Astro
    ---@class AstroBase
    ---@field state number
    ---@field speed number
    ---@field sprint number
    ---@field velocity Vector
    ---@field ratio number
    ---@field body Entity
    ---@field physobj PhysObj
    ---@field head Entity
    ---@field cameraPin Hologram
    ---@field seat Vehicle
    ---@field filter table
    ---@field driver Player
    AstroBase = {}
    AstroBase.__index = AstroBase

    ---AstroBase constructor
    ---@param body Entity Body hitbox
    ---@param head Entity Head hitbox
    ---@param seat Vehicle Bot seat
    ---@param health number Health of bot
    ---@param pinOffset? number Camera initial offset
    ---@param speed? number Speed of bot, default 200
    ---@param sprint? number Sprint speed of bot, default 600
    ---@param ratio? number Velocity linear interpolation ratio of bot, default 0.05
    ---@return AstroBase astro Astro object
    function AstroBase:new(body, head, seat, health, pinOffset, speed, sprint, ratio)
        local physobj = body:getPhysicsObject()
        physobj:setMass(1000)
        seat:setParent(body)
        seat:setColor(Color(0, 0, 0, 0))

        head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        head:setMass(100)
        head:setParent(body)

        body:setHealth(health)
        body:setMaxHealth(health)
        body:setPhysMaterial("Solidmetal")

        local pin = hologram.create(
            head:getPos() + pinOffset or Vector(),
            Angle(),
            "models/hunter/plates/plate.mdl"
        )
        if pin then
            pin:setColor(Color(0, 0, 0, 0))
            pin:setParent(head)
        end

        local astro = setmetatable(
            {
                state = 0,
                speed = speed or 200,
                sprint = sprint or 600,
                velocity = Vector(),
                ratio = ratio or 0.05,
                body = body,
                physobj = physobj,
                head = head,
                cameraPin = pin,
                seat = seat,
                filter = {body, head, seat},
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
        -- Astro think
        hook.add("Think", "AstroThink" .. id, function()
            astro:think()
        end)
        -- Astro damage
        hook.add("PostEntityTakeDamage", "AstroDamage" .. id, function(target, _, _, amount)
            if target ~= body then return end
            astro:damage(amount)
        end)
        -- Use Astro to seat
        hook.add("PlayerUse", "AstroUse" .. id, function(ply, ent)
            if ent ~= body then return end
            local permited, _ = hasPermission("player.enterVehicle", ply)
            if !permited then return end
            ply:enterVehicle(seat)
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
        dir.z = math.clamp(dir.z + getKeyDirection(self.driver, IN_KEY.SPEED, IN_KEY.JUMP), -1, 1)
        return dir
    end

    function AstroBase:think()
        local frametime = game.getTickInterval()
        if isValid(self.driver) then
            local dir = self:getDirection()
            local speed = self.driver:keyDown(IN_KEY.DUCK) and self.sprint or self.speed
            self.velocity = math.lerpVector(self.ratio, self.velocity, dir * speed * 100 * frametime)
            self.physobj:setVelocity(self.velocity)
            local eyeangles = self.driver:getEyeAngles()
            local ang = self.body:worldToLocalAngles(eyeangles)
            local angvel = ang:getQuaternion():getRotationVector() - self.body:getAngleVelocity() / 5
            self.physobj:addAngleVelocity(angvel)
            self.head:setAngles(math.lerpAngle(0.5, self.head:getAngles(), self.seat:worldToLocalAngles(eyeangles)))
            hook.run("AstroThink", self, self.driver)
        end
        self.seat:setAngles(Angle())
    end

    ---Add ignore entity to Astro
    ---@param ent any An entity to add to ignore
    function AstroBase:addIgnore(ent)
        table.insert(self.filter, ent)
    end

    ---Eye trace for Astro
    ---@return table? TraceResult Result of the trace
    function AstroBase:eyeTrace()
        if !isValid(self.driver) then return end
        local pos = self.driver:getEyePos()
        local ang = self.driver:getEyeAngles()
        return trace.line(pos, pos + ang:getForward() * 16384, self.filter)
    end


    local function findInWhitelist(whitelist, ply)
        if table.hasValue(whitelist, ply:getSteamID()) then
            return true
        end
        local name = ply:getName()
        for _, nick in ipairs(whitelist) do
            if string.find(name, nick) then
                return true
            end
        end
        return false
    end

    ---PlayerEnteredVehicle hook
    ---@param ply Player
    ---@param seat Vehicle
    function AstroBase:enter(ply, seat)
        if self.seat == seat then
            if PROTECT and !findInWhitelist(WHITELIST, ply) then
                timer.simple(0.1, function()
                    pcall(enableHud, ply, true)
                    pcall(printHud, "You're not in whitelist of this Astro")
                    pcall(enableHud, ply, false)
                    seat:ejectDriver()
                end)
            end
            self.driver = ply
            seat:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.NONE)
            ply:setColor(Color(255, 255, 255, 0))
            self.physobj:enableGravity(false)
            net.start("OnEnter")
            net.writeEntity(self.cameraPin)
            net.writeEntity(self.body)
            net.send(ply)
            hook.run("AstroActivate", self, ply)
        end
    end


    function AstroBase:leave(ply, seat)
        if self.seat == seat then
            self.driver = nil
            seat:setCollisionGroup(COLLISION_GROUP.VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            ply:setColor(Color(255, 255, 255, 255))
            self.physobj:enableGravity(true)
            net.start("OnLeave")
            net.send(ply)
            hook.run("AstroDeactivate", self, ply)
        end
    end


    function AstroBase:setState(state)
        self.state = state
    end

    function AstroBase:getState()
        return self.state
    end

    function AstroBase:isAlive()
        return self.body:getHealth() > 0
    end

    function AstroBase:damage(amount)
        if !self:isAlive() then return end
        local health = self.body:getHealth()
        local maxhealth = self.body:getMaxHealth()
        amount = hook.run("AstroDamage", self, amount) or amount
        self.body:setHealth(math.clamp(health - amount, 0, maxhealth))
        if !self:isAlive() then
            if self.driver then enableHud(self.driver, false) end
            self.driver = nil
            self.seat:ejectDriver()
            self.physobj:enableGravity(true)
            self.head:setParent(nil)
            self.head:setFrozen(false)
            self.head:setPos(self.head:getPos())
            self.head:setCollisionGroup(COLLISION_GROUP.NONE)
            self.head:applyForceCenter(Vector(
                math.rand(-15000, 15000),
                math.rand(-15000, 15000),
                math.rand(20000, 30000)
            ))
            local id = self.body:entIndex()
            hook.remove("EntityTakeDamage", "AstroDriverDefense" .. id)
            hook.remove("PlayerEnteredVehicle", "AstroEntered" .. id)
            hook.remove("PlayerLeaveVehicle", "AstroLeft" .. id)
            hook.remove("Removed", "AstroRemoved" .. id)
            hook.remove("Think", "AstroThink" .. id)
            hook.remove("PostEntityTakeDamage", "AstroDamage" .. id)
            hook.remove("PlayerUse", "AstroUse" .. id)
            timer.create("deathExplosion", 0.2, 3, function()
                local eff = effect.create()
                eff:setOrigin(self.body:getPos())
                eff:setScale(0.01)
                eff:setMagnitude(0.01)
                eff:play("explosion")
                self.body:emitSound("weapons/underwater_explode3.wav")
            end)
            self.seat:remove()
            hook.run("AstroDeath", self)
        end
    end


    net.receive("pressed", function(_, ply)
        local key = net.readInt(32)
        hook.run("InputPressed", ply, key)
    end)


    net.receive("released", function(_, ply)
        local key = net.readInt(32)
        hook.run("InputReleased", ply, key)
    end)
else
    local function createHooks(camerapoint, body)
        hook.add("InputPressed", "AstroPressed", function(key)
            if input.isControlLocked() or input.getCursorVisible() then return end
            net.start("pressed")
            net.writeInt(key, 32)
            net.send()
        end)

        hook.add("InputReleased", "AstroReleased", function(key)
            if input.isControlLocked() or input.getCursorVisible() then return end
            net.start("released")
            net.writeInt(key, 32)
            net.send()
        end)

        local lastPos = body:getPos()
        local fovOffset = 0
        local slop = 0
        hook.add("CalcView", "AstroView", function(_, ang)
            local pos = body:getPos()
            local velocity = (pos - lastPos):getRotated(-body:getAngles())
            lastPos = pos
            fovOffset = math.lerp(0.1, fovOffset, (velocity.x + math.abs(velocity.y) + velocity.z) / 10)
            slop = math.lerp(0.2, slop, -velocity.y / 20)
            return {
                origin = camerapoint:getPos(),
                angles = ang + camerapoint:getLocalAngles() + Angle(0, 0, slop),
                fov = 120 + fovOffset
            }
        end)
    end

    local function removeHooks()
        hook.remove("InputPressed", "AstroPressed")
        hook.remove("InputReleased", "AstroReleased")
        hook.remove("CalcView", "AstroView")
    end

    net.receive("OnEnter", function()
        net.readEntity(function(head)
            net.readEntity(function(body)
                timer.simple(0.1, function()
                    pcall(enableHud, nil, true)
                    createHooks(head, body)
                    hook.run("AstroEntered", head, body)
                end)
            end)
        end)
    end)

    net.receive("OnLeave", function()
        timer.simple(0.1, function()
            pcall(enableHud, nil, false)
            removeHooks()
            hook.run("AstroLeave")
        end)
    end)
end
