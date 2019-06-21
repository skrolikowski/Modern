local Modern = {}

Modern.__name     = "Modern"
Modern.__mixins   = {}
Modern.__compound = {}
Modern.__index    = Modern

-- local functions
local resolveName

setmetatable(Modern, {
    __call = function(self)
        print("Error: cannot call `Modern()` directly.")
        print("------------")
        print("Hello! I am an abstract class, and therefore cannot be called.")
        print("The proper way to use me is the following:")
        print("\t1) Create a submodule of `Modern`: `local A = Modern:extend()`")
        print("\t2) Now call your new submodule: `local a = A()`")
        print("\t3) Use your submodule's instance `a` to do your bidding: a:foo('bar')")
        print("------------")
    end
})

--[[
    Checks if `Module` is a (or inherits from)...

    @return boolean
]]--
function Modern:is(obj)
    local mt = getmetatable(self)

    while mt do
        if mt == obj then
            return true
        end

        mt = getmetatable(mt)
    end

    return false
end

--[[
    Checks `Module` for inclusion of a `Mixin`.

    @return boolean
]]--
function Modern:has(obj)
    for _, mixin in pairs(self.__mixins) do
        if mixin == obj then
            return true
        end
    end

    return false
end

--[[
    Make shallow copy of `Module`.

    @return new `Module`
]]--
function Modern:copy()
    local copy = {}

    table.foreach(self, function(key, value)
        rawset(copy, key, value)
    end)

    return copy
end

--[[
    Make deep copy of `Module`.

    @return new `Module`
]]--
function Modern:clone()
    return setmetatable(self, getmetatable(self))
end

--[[
    Extend from another `Module` inheriting
      all it's goodies

    @param  table(...) - `Mixins`
    @return new `Module`
]]--
function Modern:extend(...)
    local obj   = {}
    local n,c,f = resolveName()

    table.foreach(self, function(key, value)
        if key:find('__') then
            rawset(obj, key, value)
        end
    end)

    obj.__name   = n
    obj.__index  = obj
    obj.__super  = self
    obj.__mixins = {...}
    obj:__mix()
    setmetatable(obj, self)

    return obj
end

--[[
    Return new instance of Object called.

    Arguments passed in will be redirected
     to `new` function of returning instance.

    @internal
    @return void
]]--
function Modern:__mix()
    local functions = {}

    -- Cycle through each `Mixin` making a
    --   record of any duplicate functions.
    -- TODO: this is getting messy...
    table.foreach(self.__mixins, function(_, mixin)
        table.foreach(mixin, function(key, value)
            if type(value) == 'function' then
                if key == "__new" then
                    if functions['new'] == nil then
                        functions['new'] = {}
                    end

                    table.insert(functions['new'], value)
                elseif string.sub(key, 1, 2) == "__" then
                    -- continue..
                elseif key == 'new' then
                    -- continue..
                else
                    -- initialize..
                    if functions[key] == nil then
                        functions[key] = {}
                    end

                    table.insert(functions[key], value)
                end
            end
        end)
    end)

    -- compound function calls with same key
    -- TODO: this is getting messy...
    table.foreach(functions, function(key, value)
        self.__compound[key] = {}

        -- base function (if available)
        if type(self[key]) == 'function' then
            table.insert(self.__compound[key], self[key])
        end

        -- mixin functions
        for _, func in pairs(value) do
            table.insert(self.__compound[key], func)
        end

        rawset(self, key, function(...)
            local output = {}  -- collect return values

            for _, func in pairs(self.__compound[key]) do
                for _, out in pairs({ func(...) }) do
                    table.insert(output, out)
                end
            end

            return unpack(output)  -- return collected values
        end)
    end)
end

--[[
    Return new instance of Object called.

    Arguments passed in will be redirected
     to `new` function of returning instance.

    @param  ... - arguments
    @return new `Module` instance
]]--
function Modern:__call(...)
    local inst  = setmetatable({}, self)
    local n,c,f = resolveName()

    inst.__name  = n
    inst.__index = inst

    if inst['new'] then
        inst:new(...)
    end

    return inst
end

--[[
    Return string representation of Object.

    @return string(out)
]]--
function Modern:__tostring()
    local out    = ""
    local newln  = "\n"
    local tab    = "\t"
    local sep    = string.rep(tab, 2)
    local exists = {}
    local symbol

    out = out .. tab .. "Property" .. sep .. "Type" .. newln
    out = out .. "--------------------------------" .. newln

    local function tostringHelper(mt, lvl)
        if mt == nil then return out end
        table.foreach(mt, function(key, value)
            if string.sub(key, 0, 2) ~= "__" then
                if exists[key] then
                    symbol = "^"
               elseif self.__compound[key] and #self.__compound[key] > 1 then
                    symbol = "+"
                else
                    symbol = "-"
                end

                if type(value) == 'boolean' then
                    value = type(value) .. (value and 'true' or 'false')
                elseif type(value) == 'string' or type(value) == 'number' then
                    value = type(value) .. "(" .. value .. ")"
                else
                    value = type(value)
                end

                out = out .. "[" .. symbol .. "]" .. tab .. mt.__name .. sep .. key .. sep .. value .. newln
                exists[key] = true
            end
        end)

        return tostringHelper(getmetatable(mt), lvl + 1)
    end

    return tostringHelper(self, 0)
end

resolveName = function()
    local pattern  = "(%w+)%s*=%s*(%w+)[:|.](%w+)"
    local info     = debug.getinfo(3, "Sl")
    local source   = string.gsub(info.source, "@", "")
    local lineNum  = 0
    local lineData = ""

    for line in io.lines(source) do
        lineNum  = lineNum + 1
        lineData = line

        if lineNum == info.currentline then
            break
        end
    end

    return string.match(lineData, pattern)
end

return Modern