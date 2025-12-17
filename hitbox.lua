--@name Hitbox
--@author AstricUnion
--@server

--Hitbox class
---@class hitbox
local hitbox = {}


---Cube-formed hitbox
---@param pos Vector Position of hitbox
---@param angle Angle Angle of hitbox
---@param size Vector Size of hitbox
---@param freeze boolean? Make hitbox freezed, default false
---@param visible boolean? Make hitbox visible, default false
---@return Entity hitbox Hitbox entity
function hitbox.cube(pos, angle, size, freeze, visible)
    local pr = prop.createCustom(
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
    if !visible then pr:setColor(Color(255, 255, 255, 0)) end
    return pr
end


---Cylinder-formed hitbox
---@param pos Vector Position of hitbox
---@param angle Angle Angle of hitbox
---@param size Vector Size of hitbox
---@param freeze boolean? Make hitbox freezed, default false
---@param visible boolean? Make hitbox visible, default false
---@param polygons number? Cylinder polygons, default 16
---@return Entity hitbox Hitbox entity
function hitbox.cylinder(pos, angle, size, freeze, visible, polygons)
    local vertices = {}
    polygons = polygons or 16
    for i=1,polygons do
        local ang = math.rad((360 / polygons) * i)
        local x = math.cos(ang) * size.x
        local y = math.sin(ang) * size.y
        table.insert(vertices, Vector(x, y, size.z / 2))
        table.insert(vertices, Vector(x, y, -size.z / 2))
    end
    local pr = prop.createCustom(
        pos,
        angle,
        {
            vertices
        },
        freeze
    )
    if !visible then pr:setColor(Color(255, 255, 255, 0)) end
    return pr
end


return hitbox
