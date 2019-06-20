package.path = "../../../?.lua;" .. package.path

function love.conf(t)
    io.stdout:setvbuf('no')

    t.version  = '11.2'
    t.console  = false

    t.window.title      = 'Modern Examples - Love2D'
    t.window.x          = 25
    t.window.y          = 25
    t.window.width      = 500
    t.window.height     = 500
    t.window.fullscreen = false
end