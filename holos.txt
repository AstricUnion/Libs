--@name HoloCreator
--@author AstricUnion
--@server

SubHolo = {}
SubHolo.__index = SubHolo

---SubHolo structure, stores subhologram data
---@param pos Position of holo, default Vector()
---@param ang Angle of holo, default Angle()
---@param model Model of holo, default "models/hunter/blocks/cube025x025x025.mdl"
---@param scale Scale of holo, default Vector(1, 1, 1)
---@param suppress_light Suppress light of the holo, default false
---@param color Color of holo, default full white
---@param mat Material of holo, default uses model material
function SubHolo:new(pos, ang, model, scale, suppress_light, color, mat)
    local self = setmetatable(
        {
            pos = pos or Vector(),
            ang = ang or Angle(),
            model = model or "models/hunter/blocks/cube025x025x025.mdl",
            scale = scale or Vector(1, 1, 1),
            suppress_light = suppress_light or false,
            color = color or Color(255, 255, 255, 0),
            mat = mat or nil
        },
        SubHolo
    )
    return self
end
setmetatable(SubHolo, {__call = SubHolo.new})



Trail = {}
Trail.__index = Trail

---Trail structure, stores hologram trail data
---@param startSize The start size of the trail (0-128)
---@param endSize The end size of the trail (0-128)
---@param length The length size of the trail
---@param mat The material of the trail
---@param color The color of the trail
---@param attachmentID Optional attachmentid the trail should attach to
---@param additive If the trail's rendering is additive
---@return Trail object
function Trail:new(startSize, endSize, length, mat, color, attachmentID, additive)
    local self = setmetatable(
        {
            startSize = startSize,
            endSize = endSize,
            length = length,
            mat = mat,
            color = color,
            attachmentID = attachmentID,
            additive = additive
        },
        Trail
    )
    return self
end
setmetatable(Trail, {__call = Trail.new})


Holo = {}
Holo.__index = Holo

---Holo structure, stores hologram data
---@param subholo SubHolo structure
---@param trail Trail structure
function Holo:new(subholo, trail)
    local self = setmetatable(
        {
            subholo = subholo,
            trail = trail
        },
        Holo
    )
    return self
end
setmetatable(Holo, {__call = Holo.new})


---Creates and parents holograms to first hologram, to create one object
---@param ... ... List of Holo structures
function hologram.createPart(...)
    local main_holo
    for i, holo in ipairs({...}) do
        local holo_obj = hologram.create(
            holo.subholo.pos,
            holo.subholo.ang,
            holo.subholo.model,
            holo.subholo.scale
        )
        holo_obj:suppressEngineLighting(holo.subholo.suppress_light)
        holo_obj:setColor(holo.subholo.color)
        if holo.trail then
            holo_obj:setTrails(
                holo.trail.startSize,
                holo.trail.endSize,
                holo.trail.length,
                holo.trail.mat,
                holo.trail.color,
                holo.trail.attachmentID,
                holo.trail.additive
            )
        end
        if holo.subholo.mat then holo_obj:setMaterial(holo.subholo.mat) end
        holo_obj:setPos(chip():getPos() + holo_obj:getPos())
        if i == 1 then
            main_holo = holo_obj
            continue
        end
        holo_obj:setParent(main_holo)
    end
    return main_holo
end

