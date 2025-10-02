--@name Sounds
--@author maxobur0001
--@shared

if SERVER then

    --- Sound data
    ---@param name string Sound name to index
    ---@param volume number Sound volume
    ---@param looping boolean Is sound looping
    ---@param url string Sound URL (I'm recomending DropBox)
    Sound = {}
    Sound.__index = Sound

    function Sound:new(name, volume, looping, url)
        local self = setmetatable(
            {
                name = name,
                volume = volume,
                looping = looping or false,
                url = url
            },
            Sound
        )
        return self
    end
    setmetatable(Sound, {__call = Sound.new})

    function preloadSounds(...)
        for _, snd in ipairs({...}) do
            timer.simple(0.5, function()
                net.start("preloadSound")
                net.writeString(snd.url)
                net.writeString(snd.name)
                net.writeBool(snd.looping)
                net.writeInt(snd.volume, 32)
                net.send(find.allPlayers())
            end)
        end
    end


    ---Play preloaded sound
    ---@param name string
    ---@param position Vector Position or parent of the sound
    ---@param parent Entity | nil Parent of the sound
    function playSound(name, offset, parent)
        net.start("playSound")
        net.writeString(name)
        net.writeVector(offset or Vector())
        net.writeBool(parent ~= nil)
        if parent then
            net.writeEntity(parent)
        end
        net.send(find.allPlayers())
    end


    function stopSound(name)
        net.start("stopSound")
        net.writeString(name)
        net.send(find.allPlayers())
    end

else
    SOUNDS = {}
    PARENTS = {}

    net.receive("preloadSound", function()
        local url = net.readString()
        local name = net.readString()
        local loop = net.readBool()
        local volume = net.readInt(32)
        bass.loadURL(url, "3d noblock noplay", function(snd, err, errname)
            if not snd then
                print(Color(255, 0, 0), "[AstroSound]", Color(255, 255, 255), " Sound \"" .. name .. "\" error: " .. errname .. ", skip")
                return
            end
            SOUNDS[name] = snd
            print(Color(255, 0, 0), "[AstroSound]", Color(255, 255, 255), " Sound \"" .. name .. "\" loaded!")
            snd:setVolume(volume)
            snd:setLooping(loop)
            status = true
        end)
    end)

    local function playSound(name, pos)
        local sound = SOUNDS[name]
        if sound then
            if not sound:isLooping() then
                sound:setTime(0)
            end
            sound:setPos(pos)
            sound:play()
        end
    end

    net.receive("playSound", function()
        local name = net.readString()
        local pos = net.readVector()
        local is_parent = net.readBool()
        if is_parent then
            net.readEntity(function(ent)
                playSound(name, ent:getPos())
                PARENTS[name] = ent
            end)
        else
            playSound(name, pos)
        end
    end)

    net.receive("stopSound", function()
        local name = net.readString()
        local sound = SOUNDS[name]
        if sound then
            if not sound:isLooping() then
                return
            end
            sound:pause()
            sound:setTime(0)
        end
    end)

    hook.add("Think", "soundParent", function()
        for name, parent in pairs(PARENTS) do
            local snd = SOUNDS[name]
            if snd and isValid(parent) then
                snd:setPos(parent:getPos())
            end
        end
    end)
end
