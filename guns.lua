--@name Projectiles, damage and ETC
--@author AstricUnion
--@server
--@include https://raw.githubusercontent.com/AstricUnion/AstroBots/refs/heads/main/libs/fractional_timers.lua as fractional_timers
--@include https://raw.githubusercontent.com/AstricUnion/AstroBots/refs/heads/main/libs/holos.lua as holos

require("fractional_timers")
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

