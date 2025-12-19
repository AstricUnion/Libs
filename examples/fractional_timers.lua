--@name Fractional timer example
--@author AstricUnion
--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/ftimers.lua as ftimers
--@server

---@class FTimer
local FTimer = require("ftimers")

FTimer:new(10, 1, {
    [0.0] = function()
        print("started")
    end,
    [0.4] = function()
        print("4 seconds")
    end,
    [0.5] = function()
        print("5 seconds")
    end,
    [0.6] = function()
        print("6 seconds")
    end,
    ['0.8-0.9'] = function(_, fraction, relative)
        print("Fraction: ", fraction, ", relative: ", relative)
    end,
    [1.0] = function()
        print("ended")
    end
})
