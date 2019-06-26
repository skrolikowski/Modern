local Modern = {}

Modern.__index     = Modern
Modern.__name      = "Modern"
Modern.__namespace = "Modern"

-- local functions
local __compoundFunction,
      __setCompoundFunction,
      __getCompoundFunction,
      __setMixin,
      __getMixin,
      __getMixinValue,
      __resolveName


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
    Extend `Module`.

    @param  table(...) - `Mixins`
    @return new `Module`
]]--
function Modern:extend(...)
    local obj  = {}
    local name = __resolveName()

    table.foreach(self, function(key, value)
        if string.sub(key, 0, 2) == "__" then
            rawset(obj, key, value)
        end
    end)

    -- overrides
    obj.__name      = name
    obj.__namespace = self.__namespace .. "\\" .. name
    obj.__index     = obj

    -- append mixins
    table.foreach({...}, function(_, mixin)
        __setMixin(obj, mixin)
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
    rawset(self, key, value)  -- set index normally

    if type(value) == 'function' then
        if self.__module ~= nil then
            -- notify parent module of new index
            self.__module:__updateIndex(key, value)
        elseif self.__mixins ~= nil then
            -- compound mixin functions, if any
            __compoundFunction(self, key)
        end
    end
end


--[[
    Update index.
    Remix index, if an mixins

    Intercept incoming new index request.
    Check for existing mixins.

    @param   string(key)      - index name
    @param   function(value)  - index value
    @return  void
]]--
function Modern:__updateIndex(key, value)
    if self.__mixins ~= nil then
        __compoundFunction(self, key)
    end
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
    local name = __resolveName()

    inst.__name  = name
    inst.__index = inst

    if inst['new'] then
        inst:new(...)
    end

    return inst
end


--[[
    Return string representation of Object.

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
        elseif dataType == 'number'  then return "" .. value
        elseif dataType == 'boolean' then return value and 'true' or 'false'
        else                              return '<' .. dataType .. '>'
        end
    end
    local addRowToTableData = function(mt, key, value)
        if string.sub(key, 0, 2) ~= '__' then
            local dataType = type(value)
            local symbol = mt.__module and '+' or resolveSymbol(key)
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


--[[
    Return parent module.

    @return table
]]--
function Modern:__super()
    return getmetatable(self)
end


------------------------------------------
-- Local functions
------------------------------------------


--[[
    Build compound function, if identical
      function names found in `__mixins`.

    @internal
    @param   Module(obj)     - current Module
    @param   string(key)     - index name
    @param   function(value) - index value
    @return  void
]]--
__compoundFunction = function(obj, key, value)
    table.foreach(obj.__mixins, function(_, mixin)
        if type(obj.__mixins[mixin.__name][key]) == 'function' then
            -- mixin includes matching func name
            __setCompoundFunction(obj, key, obj.__mixins[mixin.__name][key])
        end
    end)

    if obj.__compound[key] ~= nil then
        rawset(obj, key, __getCompoundFunction(obj, key))
    end
end


--[[
    Set compound function helper.
    Groups functions with same names together.

    @internal
    @param   Module(obj)     - current Module
    @param   string(key)     - index name
    @param   function(value) - index value
    @return  void
]]--
__setCompoundFunction = function(obj, key, value)
    if obj.__compound == nil then
        obj.__compound = {}
    end

    if obj.__compound[key] == nil then
        -- add this modules func first..
        obj.__compound[key] = { rawget(obj, key) }
    end

    -- append mixin func..
    table.insert(obj.__compound[key], value)
end


--[[
    Get compound function helper.
    Calls group of functions with same name.

    Notes:
    - Returns comma delimited results (if available).

    @internal
    @param   Module(obj)     - current Module
    @param   string(key)     - index name
    @param   function(value) - index value
    @return  mixed
]]--
__getCompoundFunction = function(obj, key)
    return function(...)
        local output = {}  -- collect return values

        for _, func in pairs(obj.__compound[key]) do
            for _, out in pairs({ func(...) }) do
                table.insert(output, out)
            end
        end

        return unpack(output)  -- return collected values
    end
end


--[[
    Load mixin for this Module.
    Mixin will also have a link back to this Module.

    @internal
    @param   Module(obj)  - current Module
    @param   Module(key)  - mixin to add
    @return  void
]]--
__setMixin = function(obj, mixin)
    assert(mixin.__name ~= nil, "Please make sure your table has a `__name` property (e.g. `{ __name = 'Example' }`)")

    if not obj.__mixins then
        obj.__mixins = {}
    end

    obj.__mixins[mixin.__name] = mixin
    mixin.__module = obj
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


return Modern