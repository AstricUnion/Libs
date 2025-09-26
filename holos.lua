--@name HoloCreator
--@author AstricUnion
--@server

local CHIPPOS = chip():getPos()

---Function to create SubHolo
---@param pos? Vector Position, default Vector()
---@param ang? Angle Angle, default Angle()
---@param model? string Model of holo, default "models/hunter/blocks/cube025x025x025.mdl"
---@param scale? Vector of holo, default Vector(1, 1, 1)
---@param suppress_light? boolean Suppress light of the holo, default false
---@param color? Color of holo, default full white
---@param mat? string of holo, default uses model material
---@return Hologram?
function SubHolo(pos, ang, model, scale, suppress_light, color, mat)
    local holo = {
        pos = pos or Vector(),
        ang = ang or Angle(),
        model = model or "models/hunter/blocks/cube025x025x025.mdl",
        scale = scale or Vector(1, 1, 1),
        suppress_light = suppress_light or false,
        color = color or Color(255, 255, 255),
        mat = mat or nil
    }
    local holo_obj = hologram.create(
        CHIPPOS + holo.pos,
        holo.ang,
        holo.model,
        holo.scale
    )
    if not holo_obj then
        throw("Can't create hologram with model " .. holo.model)
        return
    end
    holo_obj:suppressEngineLighting(holo.suppress_light)
    holo_obj:setColor(holo.color)
    if holo.mat then holo_obj:setMaterial(holo.mat) end
    return holo_obj
end


---Function Rig, to create rig holograms
---@param pos? Vector Position, default Vector()
---@param ang? Angle Angle, default Angle()
---@param visible? boolean Turn on visibility (for designing)
---@return Hologram?
function Rig(pos, ang, visible)
    local holo = {
        pos = pos or Vector(),
        ang = ang or Angle(),
        model = "models/hunter/blocks/cube025x025x025.mdl",
        color = Color(255, 255, 255, visible and 255 or 0),
    }
    local holo_obj = hologram.create(
        CHIPPOS + holo.pos,
        holo.ang,
        holo.model
    )
    if not holo_obj then
        throw("Can't create hologram with model " .. holo.model)
        return
    end
    holo_obj:setColor(holo.color)
    return holo_obj
end



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
    return setmetatable(
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
end
setmetatable(Trail, {__call = Trail.new})


Holo = {}
Holo.__index = Holo

---Holo structure, stores hologram data
---@param subholo Hologram Hologram to spawn
---@param trail Trail structure
function Holo:new(subholo, trail)
    return setmetatable(
        {
            subholo = subholo,
            trail = trail
        },
        Holo
    )
end
setmetatable(Holo, {__call = Holo.new})


---Creates and parents holograms to first hologram, to create one object
---@param ... ... List of Holo structures
function hologram.createPart(...)
    local main_holo
    for i, holo in ipairs({...}) do
        if holo.trail then
            holo.subholo:setTrails(
                holo.trail.startSize,
                holo.trail.endSize,
                holo.trail.length,
                holo.trail.mat,
                holo.trail.color,
                holo.trail.attachmentID,
                holo.trail.additive
            )
        end
        if i == 1 then
            main_holo = holo.subholo
            continue
        end
        holo.subholo:setParent(main_holo)
    end
    return main_holo
end

