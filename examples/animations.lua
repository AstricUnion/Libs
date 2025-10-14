--@name Tweens example
--@author AstricUnion
--@server
--@include astricunion/libs/tweens.lua

require("astricunion/libs/tweens.lua")

local holo = hologram.create(chip():getPos(), Angle(), "models/holograms/cube.mdl")
if !holo then return end
local tween = Tween:new()

CHIPPOS = chip():getPos()

-- Add parallel params
tween:add(
    Param:new(1, holo, PROPERTY.POS, CHIPPOS + Vector(50, 0, 0), math.easeInOut),
    Param:new(3, holo, PROPERTY.LOCALANGLES, Angle(0, 180, 0), math.easeInOutQuint)
)

-- Sleep for 1 second
tween:sleep(1)

-- Next params will be chained
tween:add(
    Param:new(1, holo, PROPERTY.POS, CHIPPOS, math.easeInOut),
    Param:new(3, holo, PROPERTY.LOCALANGLES, Angle(0, -180, 0), math.easeInOutQuint, function()
        -- Callback on ending
        print("Ended!")
    end)
)

-- Start a tween
tween:start()

-- To pause it you can use
-- tween:pause()
-- Default all tweens are paused


