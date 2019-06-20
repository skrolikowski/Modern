# Modern

A module/mixin system written in the Lua programming language.

* [Use Case](#Use Case)
* [Installation](#Installation)
* [Getting Started](#Getting Started)
* [Further Usage](#Further Usage)
* [Examples](#Examples)
* [API](#API)
* [License](#License)

## Use Case

A **module** can be thought of as a unit (of code), which is used to facilitate a more complex purpose (our program). Lua doesn't naturally come pre-built with the idea of a `class`, however it offers the power of `metatables` to imitate inheritance. This idea is the main idea behind `Modern`, but with a bit more.

### What's in the box?

**Inheritance** - all modules can be inherited from or inherit from another module.

**Mixins** - extend your modules beyond their ability without affecting the inheritance chain.

**Utility Functions** - check out the [API](#API)

## Installation

**Direct Download**

1. Download the latest release from Modern's [release page](https://github.com/skrolikowski/Modern/releases).
2. Unpack and upload to a folder that is recognized by `LUA_PATH`.

**LuaRocks**

```
luarocks install modern
```

## Getting Started

1) Simply include `modern` within a new file.

```lua
local Modern = require 'modern'
```

2) Extend from `Modern` to create a fresh module, inheriting all it's functionality.

```lua
local Player = Modern:extend()
```

3) Now you can add additional functionality to your module.

```Lua
-- `new` automatically runs when Module is called
function Player:new(x, y)
	self.x = x
    self.y = y
end
```

> Notice: any functions with conflicting names will override it's parent's function with the same name. `Mixins`, on the other hand, will compound additional functions with conflicting names.

## Further Usage

### Polymorphism

`Modern` allows you to create polymorphic relationships with other `Modules`.

```lua
local Modern = require 'modern'
local Enemy  = Modern:extend() -- inherits everything from `Modern`
local Orc    = Enemy:extend()  -- inherits everything from `Enemy`
local Troll  = Enemy:extend()  -- inherits everything from `Enemy`
```

### Mixins

`Mixins` are added as arguments when calling `extend`. You can add another `Module` or a basic `table` as an argument. Any functions with conflicting names will compound so that they are all fired in sequence when called.

```lua
local Modern = require 'modern'
local AABB   = require 'mixins.AABB'
local FSM    = require 'mixins.FSM'
local Enemy  = Modern:extend(AABB, FSM)
```

A use case for using `Mixins` would be adding a **F**inite **S**tate **M**achine to your `Module` (in this case `Enemy`). It doesn't make sense to inherit from `FSM`, but we want to include the functionality to update our `Enemy` states each game cycle. By adding `FSM` as a mixin expands the base `Module`'s functionality.

## Examples

### Enemies

In this example we create a simple enemy hierarchy. Notice the call to the parent's `new` function: `self.__super:new(x, y)`. If not called, the parent's `new` would be skipped. Our `Gnome` module sets it's own attack power, which will override the `attack` value from `5`  to `10`.

```lua
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
```

**Running the code...**

```bash
$ lua
> gnome = Gnome(100, 125)
> print(gnome.x, gnome.y)  # 100, 125
> gnome:strike()           # Gnome strikes for 10
```

### Mixins

In this (silly) example we'll show an example using mixins and how conflicting function names are handled.

```lua
local Modern = require 'modern'
local M1     = Modern:extend()
local M2     = Modern:extend()
local MM     = Modern:extend(M1, M2)

function M1:foo()
    print(self.__name .. ' foo!')
end

function M2:foo()
    print(self.__name .. ' bar!')
end

function MM:foo()
    print(self.__name .. ' baz!')
end
```

**Running the code...**

```bash
$ lua
> mm = MM(100, 125)
> mm:foo()  # MM foo!
            # MM bar!
            # MM baz!
```

Notice how all 3 `foo` functions are called (in order of inclusion).

### Love2D

[Love2D](https://love2d.org/) is a fantastic framework to get you up and running with graphics, audio, and easy window configurations. This example shows how to use `Modern` to draw multiple layers using `Mixins`.

**First** we'll create a `Player` module including an `AABB` module, which provides axis-aligned bounding box functionality for collision, and in our example, debugging.

```lua
-- player.lua
local Modern = require 'modern'
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
    love.graphics.draw(self.image, self:center())
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
        love.graphics.draw(self.image, self.x, self.y, self.width, self.height)
    end
end

return Player
```

**Next**, using Love2D we draw the `player` instance.

```lua
-- main.lua
local Player = require 'player'
local player

function love.load()
    player = Player(50, 50, 'player.png')
    player.debug = true
end

function love.draw()
    player:draw()
end
```

**Finally**, our reward!

![Screencap](https://raw.githubusercontent.com/skrolikowski/Modern/master/examples/Love2D/screencap.PNG)

## API

### Modern

`__call` - Create new `Module` instance.

`is(obj)` - Checks if `Module` is a (or inherits from)...

`has(obj)` - Checks `Module` for inclusion of a `Mixin`.

`copy()` - shallow copy (using `rawset`) of `Module`.

`clone()` - Deep copy (including `metatables`) of `Module`.

`extend(...)` - Extend from another `Module` inheriting all it's goodies.

`__tostring()` - Visual version of `Module` showing properties.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


