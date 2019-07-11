package.path = "../../?.lua;" .. package.path
dbg = require 'debugger'
dbg.auto_where = 2

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

local g1 = Gnome(70, 80, 10)
local g2 = Gnome(40, 50, 5)

print(g1.x, g1.y, g1.attack)
print(g2.x, g2.y, g2.attack)

g1:strike()
g2:strike()