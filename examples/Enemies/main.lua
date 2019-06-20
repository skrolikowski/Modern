package.path = "../../?.lua;" .. package.path

local Modern = require 'modern'
local Enemy  = Modern:extend()
local Gnome  = Enemy:extend()

function Enemy:new(x, y)
    self.x = x
    self.y = y
    self.attack = 5
end

function Gnome:new(x, y)
    self.__super:new(x, y) -- call parent `new`
    self.attack = 10
end

function Gnome:strike()
    print(self.__name .. ' strikes for ' .. self.attack)
end

--

local gnome = Gnome(100, 125)

print(gnome.x, gnome.y)

gnome:strike()