local Modern = {}

Modern.__name   = "Modern"
Modern.__mixins = {}
Modern.__index = Modern

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
    local obj = {}

    table.foreach(self, function(key, value)
        if key:find('__') then
            rawset(obj, key, value)
        end
    end)

    obj.__index  = obj
    obj.__super  = self
    obj.__mixins = {...}
    setmetatable(obj, self)

    return obj
end

--[[
    Return new instance of Object called.

    Arguments passed in will be redirected
     to `new` function of returning instance.

    @internal
    @param  ... - arguments
    @return Modern
]]--
function Modern:__mix(mixins)
    local properties = {}

    -- Cycle through each "module"
    --   and include any new properties.
    table.foreach(mixins, function(_, mixin)
        table.foreach(mixin, function(key, value)
            if not key:find('__') then
                if properties[key] == nil then
                    if self[key] then
                        properties[key] = { self[key] }
                    else
                        properties[key] = {}
                    end
                end
                table.insert(properties[key], value)
            end
        end)
    end)

    -- compound function calls with same key
    table.foreach(properties, function(key, value)
        rawset(self, key, function(...)
            local output = {}
              -- collect return values
            for _, func in pairs(value) do
                for _, out in pairs({ func(...) }) do
                    table.insert(output, out)
                end
            end
            -- return collected values
            return unpack(output)
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
    local inst = setmetatable({}, self)

    inst.__name  = debug.getinfo(1, 'n').name
    inst.__index = inst
    inst:__mix(self.__mixins)

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

    out = out .. "[#]" .. tab .. " `" .. self.__name .. "`" .. newln
    out = out .. "------------" .. newln

    local function tostringHelper(mt, lvl)
        if mt == nil then return out end
        table.foreach(mt, function(key, value)
            if not key:find('__') then
                if exists[key] then
                    symbol = "^"
               elseif self.__mixins[key] then
                    symbol = "+"
                else
                    symbol = "-"
                end

                out = out .. "[" .. symbol .. "]" .. tab .. key .. sep .. type(value) .. newln
                exists[key] = true
            end
        end)

        return tostringHelper(getmetatable(mt), lvl + 1)
    end

    return tostringHelper(self, 0)
end

return Modern