package.path = "../../?.lua;" .. package.path

local Modern = require 'modern'

--

local M1 = Modern:extend()

function M1:new() print('M1:new') end
function M1:foo() print('M1:foo') end

--

local M2 = Modern:extend()

function M2:new() print('M2:new') end
function M2:foo() print('M2:foo') end

--

local MM = Modern:extend(M1, M2)

function MM:new() print('MM:new') end
function MM:foo() print('MM:foo') end

--

local mm = MM()

mm:foo()