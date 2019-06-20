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