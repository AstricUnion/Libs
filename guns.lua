--@name Projectiles, damage and ETC
--@author AstricUnion
--@shared
--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/ftimers.lua as ftimers
--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
require("ftimers")

if SERVER then
    require("holos")

    local projectiles = {}


    ---------------------- Blaster projectile ----------------------

    -- Explosion effect
    local eff = effect.create()

    local function blasterEffect(position)
        eff:setOrigin(position)
        eff:play("Explosion")
    end


    BlasterProjectile = {}
    BlasterProjectile.__index = BlasterProjectile

    ---Create new blaster projectile 
    ---@param ignore table | Entity Whitelist of projectile 
    ---@param position Vector Position of a projectile 
    ---@param angle Angle Angle and direction of a projectile
    ---@param velocity number | nil Velocity of a projectile. Default 10000
    ---@param scale number | nil Scale of a projectile. Default 1
    ---@param damage number | nil Maximum damage of a projectile explosion. Default 50
    ---@param radius number | nil Maximum radius of a projectile explosion. Default 50
    ---@param timeout number | nil Maximum lifetime of a projectile explosion. Default 3
    ---@return BlasterProjectile object
    function BlasterProjectile:new(ignore, position, angle, scale, velocity, damage, radius, timeout)
        local velocity = velocity or 10000
        local position = position
        local scale = scale or 1
        local holo = hologram.create(position, angle, "models/holograms/hq_sphere.mdl", Vector(4, 0.5, -0.5) * scale)
        local holo2 = hologram.create(position, angle, "models/holograms/hq_sphere.mdl", Vector(3.6, 0.45, -0.45) * scale)
        local holo3 = hologram.create(position, angle, "models/holograms/hq_sphere.mdl", Vector(3.2, 0.4, 0.4) * scale)
        holo:suppressEngineLighting(true)
        holo:setTrails(scale * 15, 0, 0, "effects/beam_generic01", Color(255, 0, 0))
        holo2:suppressEngineLighting(true)
        holo3:suppressEngineLighting(true)
        holo:setColor(Color(255, 0, 0))
        holo2:setColor(Color(250, 200, 200))
        holo2:setParent(holo)
        holo3:setParent(holo)
        holo:setVelocity(velocity * angle:getForward())
        local self = setmetatable(
            {
                holo = holo,
                ray_length = velocity / 25,
                velocity = velocity,
                damage = damage or 60,
                radius = radius or 80,
                ignore = ignore
            },
            BlasterProjectile
        )
        table.insert(projectiles, self)
        timer.simple(timeout or 3, function()
            if not isValid(self.holo) then
                return
            end
            self:explode(self.holo:getPos())
        end)
        return self
    end


    ---Explodes projectile on position and deletes it
    ---@param pos Position of explode
    function BlasterProjectile:explode(pos)
        self.holo:remove()
        game.blastDamage(pos, self.radius, self.damage)
        blasterEffect(pos)
        table.removeByValue(projectiles, self)
    end

    function BlasterProjectile:think()
        local pos = self.holo:getPos()
        local forward = self.holo:getForward()
        local trace_result = trace.line(pos, pos + forward * self.ray_length, self.ignore, MASK.SHOT_HULL)
        if trace_result.Hit then
            self:explode(trace_result.HitPos)
        end
    end

    hook.add("Think", "ExplosionProjectiles", function()
        for _, proj in ipairs(projectiles) do
            proj:think()
        end
    end)


    ----- Trooper blaster -----

    Blaster = {}
    Blaster.__index = Blaster


    function Blaster:new(pos, ignore, health, ammo, reloadtime, holo, hitbox)
        local ignore = ignore or {}
        local holo = holo or hologram.createPart(
            Holo(SubHolo(Vector(-5,0,2),Angle(0,0,0),"models/hunter/blocks/cube025x025x025.mdl",Vector(1,1,1),false,Color(255,0,0,0))),
            Holo(SubHolo(Vector(-28,0,-2),Angle(180,90,90),"models/props_combine/combinethumper001a.mdl",Vector(0.08,0.08,0.12),false,Color(255,40,40),"models/props_combine/metal_combinebridge001")),
            Holo(SubHolo(Vector(-28,0,6),Angle(0,90,90),"models/props_combine/combinethumper001a.mdl",Vector(0.08,0.08,0.12),false,Color(255,40,40),"models/props_combine/metal_combinebridge001")),
            Holo(SubHolo(Vector(-28,-5,2),Angle(-90,90,90),"models/props_combine/combinethumper001a.mdl",Vector(0.08,0.08,0.12),false,Color(255,40,40),"models/props_combine/metal_combinebridge001")),
            Holo(SubHolo(Vector(-28,5,2),Angle(90,90,90),"models/props_combine/combinethumper001a.mdl",Vector(0.08,0.08,0.12),false,Color(255,40,40),"models/props_combine/metal_combinebridge001")),
            Holo(SubHolo(Vector(-19,0,12),Angle(180,0,0),"models/combine_dropship_container.mdl",Vector(0.12,0.12,0.12),false,Color(255,40,40),"models/props_combine/metal_combinebridge001")),
            Holo(SubHolo(Vector(25,0,2),Angle(90,0,0),"models/Items/combine_rifle_ammo01.mdl",Vector(1.8,1.8,1.8),false,Color(255,40,40)))
        )
        local x, y, z = 50, 10, 10
        local hitbox = hitbox or prop.createCustom(pos, Angle(), {{
            Vector(-x / 2, -y, -z), Vector(x, -y, -z), Vector(x, y, -z), Vector(-x / 2, y, -z),
            Vector(-x / 2, -y, z), Vector(x, -y, z), Vector(x, y, z), Vector(-x / 2, y, z),
        }}, true)
        hitbox:setColor(Color(0, 0, 0, 0))
        holo:setPos(pos)
        holo:setParent(hitbox)
        hitbox:setMass(200)
        table.insert(ignore, hitbox)
        local self = setmetatable(
            {
                holo = holo,
                hitbox = hitbox,
                health = health or 500,
                reloadtimer = "blasterReload" .. tostring(holo:entIndex()),
                ammo = ammo or 4,
                maxammo = ammo or 4,
                reloadtime = reloadtime or 0.5,
                ignore = ignore
            },
            Blaster
        )
        return self
    end


    ---Add to projectile whitelist (as example, second blaster)
    ---@param ent Entity
    function Blaster:addIgnore(ent)
        table.insert(self.ignore, ent)
    end


    function Blaster:shoot(on_shoot, on_reload, after_reload)
        if self.ammo == 0 then
            return
        end

        FTimer:new(0.3, 1, {
            ["0-0.5"] = function(_, _, fraction)
                local smoothed = math.easeInCubic(fraction)
                self.holo:setLocalPos(Vector(smoothed * -20, 0, 0))
            end,
            ["0.5-1"] = function(_, _, fraction)
                local smoothed = math.easeInCubic(1 - fraction)
                self.holo:setLocalPos(Vector(smoothed * -20, 0, 0))
            end,
            [1] = function()
                self.holo:setLocalPos(Vector(0, 0, 0))
            end
        })

        local angles = self.hitbox:getAngles()
        local pos = self.hitbox:getPos()

        BlasterProjectile:new(self.ignore, pos, angles)
        self.ammo = self.ammo - 1

        if on_shoot then on_shoot() end
        if !timer.exists(self.reloadtimer) and self.ammo == 0 and self:isAlive() then
            if on_reload then on_reload() end
            timer.create(self.reloadtimer, self.reloadtime, 1, function()
                self.ammo = self.maxammo
                if after_reload then after_reload() end
            end)
            FTimer:new(0.5, 1, {
                ["0-1"] = function(_, _, fraction)
                    local smoothed = math.easeInOutSine(fraction)
                    self.holo:setLocalAngles(Angle(360 * smoothed, 0, 0))
                end
            })
        end
    end


    function Blaster:damage(amount)
        if not self:isAlive() then return end
        self.health = self.health - amount
        if not self:isAlive() then
            local parented_pos = self.hitbox:getPos()
            self.hitbox:setParent(nil)
            self.hitbox:setPos(parented_pos)
            self.hitbox:setFrozen(false)
            local eff = effect.create()
            eff:setOrigin(parented_pos)
            eff:setScale(0.01)
            eff:setMagnitude(0.01)
            eff:play("explosion")
            self.hitbox:emitSound("weapons/underwater_explode3.wav")
        end
    end


    function Blaster:isAlive()
        return self.health > 0
    end



    ---------------------- Laser ----------------------

    ---Just a laser. Parents to blaster
    ---@class Laser
    Laser = {
        ---@type Entity
        parent = nil,

        ---@type number
        diameter = nil,

        ---@type number
        charge = nil
    }
    Laser.__index = Laser


    ---Creates laser object
    ---@param parent Entity Object to parent
    ---@param radius number? Radius of the laser, default 10
    ---@param damage number? Damage of the laser, default 5
    ---@param damage_radius number? Damage radius of the laser, default 7.5
    ---@return Laser?
    function Laser:new(parent, radius, damage, damage_radius)
        return setmetatable(
            {
                parent = parent,
                diameter = (radius or 10) * 2,
                charge = 1,
                damage = damage or 5,
                damage_diameter = (damage_radius or 7.5) * 2
            },
            Laser
        )
    end

    ---Shoot with laser
    function Laser:start()
        net.start("laserOn")
        net.writeTable(self)
        net.send(find.allPlayers())
    end

    function Laser:think()
        local pos = self.parent:getPos()
        local res = trace.line(pos, pos + self.parent:getForward() * 16384, {self.parent})
        game.blastDamage(res.HitPos, self.diameter + self.damage_diameter, self.damage)
    end

    function Laser:increaseCharge(value)
        self.charge = math.clamp(self.charge + value, 0, 1)
    end

    function Laser:decreaseCharge(value, ended_callback)
        self.charge = math.clamp(self.charge - value, 0, 1)
        if self.charge == 0 and ended_callback then
            ended_callback()
        end
    end

    function Laser:setDamage(damage)
        self.damage = damage
    end

    function Laser:setDamageRadius(radius)
        self.damage_diameter = radius * 2
    end

    function Laser:getCharge()
        return self.charge
    end

    ---Stop shoot with laser
    function Laser:stop()
        net.start("laserOff")
        net.writeInt(self.parent:entIndex(), 32)
        net.send(find.allPlayers())
    end
else
    local LaserModel = {
        ---@type Hologram
        holo = nil,
        ---@type Hologram
        holo2 = nil,
        ---@type Hologram
        holo3 = nil,
        ---@type Entity
        parent = nil,
        ---@type number
        diameter = nil,
        ---@type number
        damage_diameter = nil
    }
    LaserModel.__index = LaserModel

    local models = {}

    function LaserModel:new(holo, holo2, holo3, parent, diameter, damage_diameter)
        return setmetatable(
            {
                holo = holo,
                holo2 = holo2,
                holo3 = holo3,
                parent = parent,
                diameter = diameter,
                damage_diameter = damage_diameter
            },
            LaserModel
        )
    end

    --- Think function. Place it in RenderOffscreen to better result
    function LaserModel:think()
        local pos = self.parent:getPos()
        local res = trace.line(pos, pos + self.parent:getForward() * 16384, {self.parent})
        local tick = game.getTickCount()
        if tick % 5 == 0 and trace.canCreateDecal() then
            trace.decal("Dark", res.HitPos, res.HitPos + res.Normal)
        end
        self.holo3:setPos(res.HitPos)
        local size = ((game.getTickCount() % 2 * -3) + self.diameter)
        self.holo3:setSize(Vector(size + self.damage_diameter))
        local dist = pos:getDistance(res.HitPos)
        self.holo:setPos(pos + (res.Normal * (dist / 2)))
        self.holo:setSize(Vector(size - 5, size - 5, dist))
        self.holo2:setSize(Vector(size, size, dist))
    end

    --- Remove laser
    function LaserModel:remove()
        if !(isValid(self.holo) and isValid(self.holo2) and isValid(self.holo3)) then return end
        self.holo:remove()
        self.holo2:remove()
        self.holo3:remove()
    end

    hook.add("RenderOffscreen", "", function()
        for _, model in pairs(models) do
            model:think()
        end
    end)

    local function laserOff(index, laser)
        local diameter = laser.diameter
        FTimer:new(0.25, 1, {
            ["0-1"] = function(_, _, fraction)
                laser.diameter = diameter * math.easeInOutCubic(1 - fraction)
            end,
            [1] = function()
                models[index] = nil
                laser:remove()
            end
        })
    end

    net.receive("laserOff", function()
        local index = net.readInt(32)
        local laser = models[index]
        if !laser then return end
        laserOff(index, laser)
    end)

    net.receive("laserOn", function()
        local tab = net.readTable()
        if models[tab.parent:entIndex()] then return end
        local holo = hologram.create(tab.parent:getPos(), tab.parent:getAngles(), "models/holograms/hq_cylinder.mdl")
        local holo2 = hologram.create(tab.parent:getPos(), tab.parent:getAngles(), "models/holograms/hq_cylinder.mdl")
        local holo3 = hologram.create(tab.parent:getPos(), tab.parent:getAngles(), "models/holograms/hq_sphere.mdl")
        if !(holo and holo2 and holo3) then return end
        holo:setParent(tab.parent)
        holo2:setParent(holo)

        holo:setLocalAngles(Angle(90, 0, 0))
        holo:suppressEngineLighting(true)
        holo:setMaterial("debug/debugwhite")

        holo3:suppressEngineLighting(true)
        holo3:setMaterial("debug/debugwhite")
        holo3:setSize(Vector(tab.diameter + tab.damage_diameter))

        holo2:suppressEngineLighting(true)
        holo2:setMaterial("debug/debugwhite")
        holo2:setColor(Color(255, 0, 0))
        holo2:setCullMode(1)
        local model = LaserModel:new(holo, holo2, holo3, tab.parent, 0, tab.damage_diameter)
        models[tab.parent:entIndex()] = model
        FTimer:new(0.25, 1, {
            ["0-1"] = function(_, _, fraction)
                model.diameter = tab.diameter * math.easeInOutCubic(fraction)
            end
        })
    end)
end
