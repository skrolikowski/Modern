-- player.lua
local Modern = require 'modern.modern'
local AABB   = Modern:extend()
local Player = Modern:extend(AABB)

function Player:new(x, y, src)
    local image = love.graphics.newImage(src)
    local w, h  = image:getDimensions( )

    self.x      = x
    self.y      = y
    self.image  = image
    self.scale  = 0.5
    self.width  = w * self.scale
    self.height = h * self.scale
    self.debug  = false
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, self.scale)
end

function AABB:new()
    -- using `Player` variables to create some more
    self.left   = self.x
    self.top    = self.y
    self.right  = self.x + self.width
    self.bottom = self.y + self.height
end

-- ...
-- Really cool, useful functions removed for brevity :p
-- ...

function AABB:draw()
    if self.debug then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    end
end

return Player