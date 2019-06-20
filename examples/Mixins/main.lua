package.path = "../../?.lua;" .. package.path

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

--

local mm = MM(100, 125)

mm:foo()