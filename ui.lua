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


---@class Bar
Bar = {}
Bar.__index = Bar


---Bar UI element
---@param x number X position
---@param y number Y position
---@param w number Width
---@param h number Height
---@param percent number Start percent (from 0. to 1.)
function Bar:new(x, y, w, h, percent)
    local renderTarget = "bar" .. tostring(x + y)
    return setmetatable(
        {
            x = x,
            y = y,
            w = w,
            h = h,
            renderTarget = renderTarget,
            percent = math.clamp(percent, 0, 1),
            label_left = nil,
            label_right = nil,
            barcolor = Color(255, 255, 255)
        },
        Bar
    )
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
    --[[ A raw light effect, poorly optimized
    if !render.renderTargetExists(self.renderTarget) then render.createRenderTarget(self.renderTarget) end
    render.selectRenderTarget(self.renderTarget)
    render.clear(Color(0, 0, 0, 0))
    render.setColor(Color(255, 255, 255))
    render.drawRectOutline(20, 20, self.w, self.h, 4)
    render.drawRect(24, 24, (self.w - 8) * self.percent, self.h - 8)
    render.drawBlurEffect(2, 2, 5)
    render.selectRenderTarget()

    render.setRenderTargetTexture(self.renderTarget)
    render.drawTexturedRect(self.x - 20, self.y - 20, 1024, 1024)
    render.setRenderTargetTexture()
    ]]

    render.drawRectOutline(self.x, self.y, self.w, self.h, 2)
    render.setColor(self.barcolor)
    render.drawRect(self.x + 4, self.y + 4, (self.w - 8) * self.percent, self.h - 8)
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

