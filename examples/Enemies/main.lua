package.path = "../../?.lua;" .. package.path


local Modern = require 'modern'

--

local Enemy = Modern:extend()

function Enemy:new(x, y)
    self.x = x
    self.y = y
    print('Enemy:new', x, y)
end

--

local Gnome = Enemy:extend()

function Gnome:new(x, y, attack)
    self.__super.new(self, x, y) -- call parent `new`
    self.attack = attack
    print(self.__name .. ':new', x, y, attack)
end

function Gnome:strike()
    print(self.__name .. ' strikes for ' .. self.attack)
end

--

local gnome = Gnome(70, 80, 10)

print(gnome.x, gnome.y)
print(gnome.attack)

gnome:strike()