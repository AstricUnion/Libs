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
    holo_obj:suppressEngineLighting(true)
    holo_obj:setColor(holo.color)
    return holo_obj
end


---@class Trail
---@field startSize number The start size of the trail (0-128)
---@field endSize number The end size of the trail (0-128)
---@field length number The length size of the trail
---@field mat string The material of the trail
---@field color Color The color of the trail
---@field attachmentID? number Optional attachmentid the trail should attach to
---@field additive? boolean If the trail's rendering is additive
Trail = {}
Trail.__index = Trail


---Trail structure, stores hologram trail data
---@param startSize number The start size of the trail (0-128)
---@param endSize number The end size of the trail (0-128)
---@param length number The length size of the trail
---@param mat string The material of the trail
---@param color Color The color of the trail
---@param attachmentID? number Optional attachmentid the trail should attach to
---@param additive? boolean If the trail's rendering is additive
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


---@class Clip
---@field pos Vector
---@field normal Vector
Clip = {}
Clip.__index = Clip

---Clip structure
---@param pos any
---@param normal Vector Angle of clip, like normal, but local
---@return table
function Clip:new(pos, normal)
    return setmetatable(
        {
            pos = pos,
            normal = normal
        },
        Clip
    )
end

setmetatable(Clip, {__call = Clip.new})


---@class Holo
---@field subholo Hologram
---@field trail Trail
---@field clips table[Clip]
Holo = {}
Holo.__index = Holo

---Holo structure, stores hologram data
---@param subholo Hologram Hologram to spawn
---@param trail? Trail Trail structure
---@param clips? table[Clip] Table with Clip structure
function Holo:new(subholo, trail, clips)
    return setmetatable(
        {
            subholo = subholo,
            trail = trail,
            clips = clips,
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
        ---@cast holo Holo
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
        if holo.clips then
            for i, clip in ipairs(holo.clips) do
                ---@cast clip Clip
                holo.subholo:setClip(
                    i,
                    true,
                    holo.subholo:getPos() + clip.pos,
                    clip.normal
                )
            end
        end
        if i == 1 then
            main_holo = holo.subholo
            continue
        end
        holo.subholo:setParent(main_holo)
    end
    return main_holo
end

