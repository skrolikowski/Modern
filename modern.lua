local Modern = {},
      __addMixin,
      __addMixer,
      __getMixin,
      __resolveName,
      __setIndex,
      __getIndex


Modern.__name      = "Modern"
Modern.__namespace = "Modern"
Modern.__module    = false
Modern.__mixins    = {}
Modern.__mixers    = {}
Modern.__index     = function(self, key)
    return Modern[key] or error('Cannot find property `' .. self.__name .. '.' .. key .. '`')
end


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
function Modern:has(mixin)
    assert(mixin.__module ~= false, "Module you are comparing is not a Mixin.")

    return self == mixin.__module
end


--[[
    Return parent module.

    @return Module|table
]]--
function Modern:super()
    return getmetatable(self)
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
    Extend `Module`.

    @param  table(...) - `Mixins`
    @return new `Module`
]]--
function Modern:extend(...)
    local obj  = {}
    local name = __resolveName()

    -- copy metamethods..
    table.foreach(self, function(key, value)
        if string.sub(key, 0, 2) == "__" then
            rawset(obj, key, value)
        end
    end)

    -- overrides!
    obj.__name      = name
    obj.__super     = self
    obj.__namespace = self.__namespace .. "\\" .. name
    obj.__index     = function(self, key)
        -- check for special cases
        --   or fallback..
        return __getIndex(self, key) or obj[key]
    end

    -- include mixins..
    table.foreach({...}, function(_, mixin)
        __addMixin(obj, mixin)
    end)

    return setmetatable(obj, self)
end


--[[
    Intercept incoming new function indexes
      in order to handle "compound functions"

    Intercept incoming new index request.
    Check for existing mixins.

    @param   string(key)      - index name
    @param   function(value)  - index value
    @return  void
]]--
function Modern:__newindex(key, value)
    __setIndex(self, key, value)
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

    if inst['new'] then
        inst:new(...)
    end

    return inst
end


--[[
    Return string representation of Object.
    TODO: this is a gnarly function

    @return string
]]--
function Modern:__tostring()
    local tableData = {{ '[ ]', 'Module', 'Namespace', 'DataType', 'Key', 'Value' }}
    local tableWidth = 0
    local colData = {}
    local overrides = {}
    local padding = 2
    local max = math.max
    local buildTableData
    local rowWidth = function(row)
        local width = #tableData[1] * 2 + 2
        table.foreach(row, function(_, value)
            width = width + value
        end)
        tableWidth = max(tableWidth, width)
    end
    local colWidths = function(row)
        table.foreach(row, function(idx, value)
            colData[idx] = max(colData[idx] or 0, #value + padding)
        end)
        rowWidth(colData)
    end
    local resolveSymbol = function(key)
        if not overrides[key] then
            overrides[key] = true
            return '-'
        end
        return '^'
    end
    local resolveValue = function(dataType, value)
        if     dataType == 'string'  then return '"' .. value .. '"'
        elseif dataType == 'number'  then return '' .. value
        elseif dataType == 'boolean' then return value and 'true' or 'false'
        else                              return '<' .. dataType .. '>'
        end
    end
    local addRowToTableData = function(mt, key, value)
        if string.sub(key, 0, 2) ~= '__' then
            local dataType = type(value)
            local symbol = mt.__module ~= false and '+' or resolveSymbol(key)
            local value = resolveValue(dataType, value)
            local row = {
                '[' .. symbol .. ']', mt.__name, mt.__namespace, dataType, key, value
            }
            colWidths(row)
            table.insert(tableData, row)
        end
    end
    buildTableData = function(mt)
        if mt == nil then return end
        table.foreach(mt, function(key, value)
            addRowToTableData(mt, key, value)
        end)
        return buildTableData(getmetatable(mt))
    end
    local buildMixinData = function(mt)
        table.foreach(mt.__mixins, function(_, mixin)
            table.foreach(mixin, function(key, value)
                addRowToTableData(mixin, key, value)
            end)
        end)
    end
    local display = function()
        local out = string.rep('-', tableWidth) .. '\n'
        table.foreach(tableData, function(idx, row)
            table.foreach(row, function(key, value)
                out = out .. '| ' .. value .. string.rep(' ', colData[key] - #value)
            end)
            out = out .. ' |\n'
            if idx == 1 then
                out = out .. string.rep('-', tableWidth) .. '\n'
            end
        end)
        return out .. string.rep('-', tableWidth)
    end

    buildTableData(self)
    buildMixinData(self)

    return display()
end


------------------------------------------
-- Local functions
------------------------------------------


--[[
    Load mixin into a Module.
    Mixin will also have a link back to this Module.

    @internal
    @param   Module(obj)  - current Module
    @param   Module(key)  - mixin to add
    @return  void
]]--
__addMixin = function(obj, mixin)
    assert(mixin.__name ~= nil, "Please make sure your table has a `__name` property (e.g. `{ __name = 'Example' }`)")

    -- link Modules..
    obj.__mixins[mixin.__name] = mixin
    mixin.__module = obj

    -- mix-in functions
    table.foreach(mixin, function(key, value)
        if type(value) == 'function' then
            __addMixer(obj, key, value)
        end
    end)
end


--[[
    Add mixin function to a Module.
    Each key will contain either one or more functions.

    @internal
    @param   Module(obj)
    @param   string(key)
    @param   function(value)
    @return  void
]]--
__addMixer = function(obj, key, value)
    if obj.__mixers[key] == nil then
        obj.__mixers[key] = { value }
    else
        table.insert(obj.__mixers[key], value)
    end
end


--[[
    Get mixin by name, included in this Module.
    If not found, will error out.

    @internal
    @param   Module(obj)  - current Module
    @param   Module(key)  - mixin to add
    @return  void
]]--
__getMixin = function(obj, mixinName)
    return obj.__mixins[mixinName] or
           error('Mixin with name `' .. mixinName .. '` does not exist.')
end


--[[
    Returns resolved names of code in line
        calling originating function.

    @internal
    @return string(name, caller, func)
]]--
__resolveName = function()
    local pattern  = "(%w+)%s*=%s*([%w]+)[:|.]?([%w]*)%((.*)%)"
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


--[[
    Intercept new function indexes.
    Create compound function if necessary.

    @internal
    @param  Module(obj)
    @param  string(key)
    @param  mixed(value)
    @return void
]]--
__setIndex = function(obj, key, value)
    if type(value) == 'function' then
        local mixers = rawget(obj, '__mixers')

        if mixers and mixers[key] then
            local funcs = { value }

            table.foreach(obj.__mixers[key] or {}, function(_, func)
                table.insert(funcs, func)
            end)

            value = function(...)
                local output = {}  -- collect return values

                for _, func in pairs(funcs) do
                    for _, out in pairs({ func(...) }) do
                        table.insert(output, out)
                    end
                end

                return unpack(output)  -- return collected values
            end
        end
    end

    rawset(obj, key, value)
end

--[[
    Intercept function index requests.
    Create compound function if necessary
      otherwise return nil and fallback..

    @internal
    @param  Module(obj)
    @param  string(key)
    @return void
]]--
__getIndex = function(obj, key)
    local mixers = rawget(obj, '__mixers')

    if mixers and mixers[key] ~= nil then
        return function(...)
            local output = {}  -- collect return values

            for _, func in pairs(mixers[key]) do
                for _, out in pairs({ func(...) }) do
                    table.insert(output, out)
                end
            end

            return unpack(output)  -- return collected values
        end
    end

    return rawget(obj, key)
end


return Modern