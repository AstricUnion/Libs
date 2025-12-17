--@name Simple gun
--@author AstricUnion
--@server
--@include http://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos

local holos = require("holos")

---@class Holo
local Holo = holos.Holo
local Rig = holos.Rig
local SubHolo = holos.SubHolo

---@class Trail
local Trail = holos.Trail

---@class Clip
local Clip = holos.Clip


local parts = {
    hand = {
        hologram.createPart(
            Holo(Rig()),
            Holo(SubHolo(Vector(0, 0, 5), Angle(), "models/props_c17/oildrum001_explosive.mdl"))
        ),
        hologram.createPart(
            Holo(Rig(Vector(0, 0, 45))),
            Holo(SubHolo(Vector(0, 0, 50), Angle(), "models/props_c17/oildrum001_explosive.mdl")),
            Holo(
                SubHolo(Vector(0, 0, 90), Angle(), nil, nil, true, Color(0, 0, 0, 0)),
                Trail(10, 50, 50, "trails/physbeam", Color(255, 255, 255))
            )
        ),
    }
}
parts.hand[1]:setParent(chip())
parts.hand[2]:setParent(parts.hand[1])

hook.add("tick", "", function()
    local res = owner():getEyeTrace()
    local angles = (parts.hand[2]:getPos() - res.HitPos):getAngle()
    parts.hand[2]:setAngles(math.lerpAngle(0.3, parts.hand[2]:getAngles(), angles + Angle(-90, 0, 0)))
end)
