--@name AstricUnion UI
--@author AstricUnion
--@client

fontMontserrat50 = render.createFont(
    "Montserrat",
    50,
    500,
    true,
    false,
    false,
    false,
    0,
    true,
    0
)



Bar = {}
Bar.__index = Bar


---Bar UI element
---@param x number X position
---@param y number Y position
---@param w number Width
---@param h number Height
---@param percent number Start percent (from 0. to 1.)
function Bar:new(x, y, w, h, percent)
    local self = setmetatable(
        {
            x = x,
            y = y,
            w = w,
            h = h,
            percent = math.clamp(percent, 0, 1),
            current_percent = math.clamp(percent, 0, 1),
            label_left = nil,
            label_right = nil,
            barcolor = Color(255, 255, 255)
        },
        Bar
    )
    return self
end


function Bar:setPercent(percent)
    self.percent = math.clamp(percent, 0, 1)
    return self
end


function Bar:setLabelLeft(label)
    self.label_left = label
    return self
end

function Bar:setLabelRight(label)
    self.label_right = label
    return self
end

function Bar:setBarColor(color)
    self.barcolor = color
    return self
end

function Bar:draw()
    self.current_percent = math.lerp(0.2, self.current_percent, self.percent)
    render.drawRectOutline(self.x, self.y, self.w, self.h, 2)
    render.setColor(self.barcolor)
    render.drawRect(self.x + 4, self.y + 4, (self.w - 8) * self.current_percent, self.h - 8)
    render.setColor(Color(255, 255, 255))
    render.setFont(fontMontserrat50)
    if self.label_left then
        render.drawText(self.x - 8, self.y - 5, self.label_left, TEXT_ALIGN.RIGHT)
    end
    if self.label_right then
        render.drawText(self.x + self.w + 8, self.y - 5, self.label_right, TEXT_ALIGN.LEFT)
    end
end

setmetatable(Bar, {__call = Bar.new})

