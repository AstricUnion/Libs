--@name Sounds
--@author maxobur0001
--@shared

if SERVER then
    -- Network strings --
    -- preloadSound
    -- preloaded
    -- playSound
    -- stopSound

    local astrosounds = {}
    setmetatable(astrosounds, {__index = astrosounds})

    ---Sound data
    ---@class Sound
    Sound = {}
    Sound.__index = Sound

    ---Create new sound
    ---@param name string Sound name to index
    ---@param volume number Sound volume
    ---@param looping boolean Is sound looping
    ---@param url string Sound URL (I'm recomending DropBox)
    function Sound:new(name, volume, looping, url)
        return setmetatable(
            {
                name = name,
                volume = volume,
                looping = looping or false,
                url = url
            },
            Sound
        )
    end
    setmetatable(Sound, {__call = Sound.new})

    ---Preload sounds for Astro. You should place it in ClientInitialize hook
    ---@param ply Player Player to send sounds
    ---@param ... Sound
    function astrosounds.preload(ply, ...)
        local sounds = {...}
        for _, snd in ipairs(sounds) do
            net.start("preloadSound")
            net.writeString(snd.url)
            net.writeString(snd.name)
            net.writeBool(snd.looping)
            net.writeInt(snd.volume, 32)
            net.send(ply)
        end
    end


    ---SoundPreloaded hook
    net.receive("preloaded", function(_, ply)
        local name = net.readString()
        hook.run("SoundPreloaded", name, ply)
    end)


    ---Play preloaded sound
    ---@param name string
    ---@param offset Vector Offset position or parent of the sound
    ---@param parent Entity | nil Parent of the sound
    ---@param plys table | Player | nil Players to send the sound
    function astrosounds.play(name, offset, parent, plys)
        net.start("playSound")
        net.writeString(name)
        net.writeVector(offset or Vector())
        net.writeBool(parent ~= nil)
        if parent then
            net.writeEntity(parent)
        end
        net.send(plys or find.allPlayers())
    end


    ---Stop preloaded sound
    ---@param name string
    function astrosounds.stop(name, plys)
        net.start("stopSound")
        net.writeString(name)
        net.send(plys or find.allPlayers())
    end

    return astrosounds

else
    local Error = {
        ---@type string
        url = nil,
        ---@type boolean
        loop = nil,
        ---@type number
        volume = nil,
        ---@type number
        error = nil,
        ---@type number
        attempts = nil,
        ---@type boolean
        in_progress = nil
    }

    function Error:new(url, loop, volume, error)
        return setmetatable(
            {
                url = url,
                loop = loop,
                volume = volume,
                error = error,
                attempts = 3,
                in_progress = false
            },
            Error
        )
    end

    local SOUNDS = {}
    local PARENTS = {}
    local ERRORS = {}

    local function message(...)
        printConsole(Color(255, 0, 0), "[AstroSound]", Color(255, 255, 255), ...)
    end

    local function preload(url, name, loop, volume)
        bass.loadURL(url, "3d noblock noplay", function(snd, err, errname)
            if not snd then
                local error = ERRORS[name]
                message(" Sound \"" .. name .. "\" error: " .. errname .. ", skip")
                if error then
                    error.attempts = error.attempts - 1
                    error.in_progress = false
                else
                    ERRORS[name] = Error:new(url, loop, volume, err)
                end
                return
            end
            SOUNDS[name] = snd
            message(" Sound \"" .. name .. "\" loaded!")
            net.start("preloaded")
            net.writeString(name)
            net.send()
            snd:setVolume(volume)
            snd:setLooping(loop)
        end)
    end

    net.receive("preloadSound", function()
        local url = net.readString()
        local name = net.readString()
        local loop = net.readBool()
        local volume = net.readInt(32)
        preload(url, name, loop, volume)
    end)


    local function errorHandler()
        while true do
            coroutine.yield()
            for name, err in pairs(ERRORS) do
                if err.attempts == 0 or SOUNDS[name] then
                    ERRORS[name] = nil
                    continue
                end
                if err.in_progress then
                    continue
                end
                coroutine.yield()
                coroutine.wait(1)
                preload(err.url, name, err.loop, err.volume)
                err.in_progress = true
            end
        end
    end

    local handlerThread = coroutine.create(errorHandler)
    hook.add("Tick", "soundPreloadErrors", function()
        coroutine.resume(handlerThread)
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
