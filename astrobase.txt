--@name AstroBase (BASE FOR ALL BOTS, DON'T WORK)
--@author AstricUnion
--@shared

if SERVER then

    --Hitbox class
    hitbox = {}


    ---Cube-formed hitbox
    ---@param pos Vector Position of hitbox
    ---@param angle Angle Angle of hitbox
    ---@param size Vector Size of hitbox
    ---@param freeze boolean Make hitbox freezed, default false
    ---@param visible boolean Make hitbox visible, default false
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
    AstroBase = {}
    AstroBase.__index = AstroBase

    ---AstroBase constructor
    ---@param states table States of Astro (REQUIRE STATE Idle AND NotInUse)
    ---@param body Entity Body hitbox
    ---@param head Entity Head hitbox
    ---@param seat Entity Bot seat
    ---@param health number Health of bot
    ---@param on_enter function Callback on entering
    ---@param on_leave function Callback on leaving
    ---@return AstroBase astro Astro object
    function AstroBase:new(states, body, head, seat, health)
        if !(states.NotInUse and states.Idle) then
            throw("States require a NotInUse and Idle")
        end
        local movement = Movement:new(seat, body)
        head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        head:setMass(100)
        local self = setmetatable(
            {
                states = states,
                state = states.NotInUse,
                health = health,
                maxhealth = health,
                movement = movement,
                body = body,
                head = head
            },
            AstroBase
        )
        return self
    end


    function AstroBase:think(active_callback)
        self.movement:think(function(dr)
            self.head:setAngles(dr:getEyeAngles())
            if active_callback then active_callback(dr) end
        end)
    end


    function AstroBase:enter(ply, seat)
        if self.movement.seat == seat then
            self.state = self.states.Idle
            seat:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.NONE)
            ply:setColor(Color(255, 255, 255, 0))
            net.start("OnEnter")
            net.writeEntity(body.head)
            net.send(ply)
        end
    end


    function AstroBase:leave(ply, seat)
        if self.movement.seat == seat then
            self.state = self.states.NotInUse
            seat:setCollisionGroup(COLLISION_GROUP.VEHICLE)
            self.head:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            ply:setColor(Color(255, 255, 255, 255))
            net.start("OnLeave")
            net.send(ply)
        end
    end


    function AstroBase:isAlive()
        return self.health > 0
    end

    function AstroBase:damage(amount, callback)
        if not self:isAlive() then return end
        self.health = self.health - amount
        if not self:isAlive() then
            if callback then callback() end
            self.movement.seat:ejectDriver()
            self.movement.physobj:enableGravity(true)
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
            self.movement.seat:remove()
        end
    end
else


end
