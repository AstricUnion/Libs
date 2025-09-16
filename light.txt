--@name Light
--@author AstricUnion
--@shared

if SERVER then
    ---Create a light with parameters
    ---@param parent Entity Parent of light
    ---@param offset Vector Vector with offset of light
    ---@param size number Size
    ---@param brightness number Brightness
    ---@param color Color Color
    function createLight(name, parent, offset, size, brightness, color)
        timer.simple(1, function()
            net.start("CreateLight")
            net.writeString(name)
            net.writeEntity(parent)
            net.writeVector(offset)
            net.writeInt(size, 32)
            net.writeInt(brightness, 32)
            net.writeColor(color)
            net.send(find.allPlayers())
        end)
    end

    function removeLight(name)
        net.start("RemoveLight")
        net.writeString(name)
        net.send(find.allPlayers())
    end
else
    local lights = {}

    net.receive("CreateLight", function()
        local name = net.readString()
        net.readEntity(function(ent)
            local offset = net.readVector()
            lights[name] = {
                light.create(
                    ent:getPos() + offset,
                    net.readInt(32),
                    net.readInt(32),
                    net.readColor()
                ),
                ent,
                offset
            }
        end)
    end)

    net.receive("RemoveLight", function()
        local name = net.readString()
        lights[name] = nil
    end)

    hook.add("RenderScene", "Lights", function()
        for _, light in pairs(lights) do
            light[1]:draw()
            if isValid(light[2]) then
                light[1]:setPos(light[2]:getPos() + light[3])
            end
        end
    end)
end
