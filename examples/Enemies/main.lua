package.path = "../../?.lua;" .. package.path

local Modern = require 'modern'
local Enemy  = Modern:extend()
local Gnome  = Enemy:extend()

function Enemy:new(...)
    local params = {...}
    self.x = params[1] or 0
    self.y = params[2] or 0
    self.attack = 5
    print(self.__name .. ':new', ...)
end

function Gnome:new(...)
    self:super():new(...) -- call parent `new`
    self.attack = 10
    print(self.__name .. ':new', ...)
end

function Gnome:strike()
    print(self.__name .. ' strikes for ' .. self.attack)
end

--

local gnome = Gnome(100, 125)

print(gnome.x, gnome.y)
print(gnome.attack)

gnome:strike()