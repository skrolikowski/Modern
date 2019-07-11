--
package.path = "../?.lua;" .. package.path
require 'busted.runner'()
--

describe('Modern - Usage Tests', function()
    local MM, MA, MB
    local _C, CA, CB, CC

    setup(function()
        MM = require 'modern'

        -- components
        _C = MM:extend()
        function _C:new() self._v1 = 42 end
        function _C:x()   return '_CX'  end
        function _C:y()   return '_CY'  end
        function _C:z()   return '_CZ'  end
        --
        CA = _C:extend()
        function CA:__new()
            self.v = self.__module.m + self.__module.n
        end
        function CA:a()   return 'CAA' end
        function CA:x()   return 'CAX' end
        --
        CB = _C:extend()
        function CB:__new()
            self:super('new')
            self.w = self.__module.m - self.__module.n
        end
        function CB:b()   return 'CBB' end
        function CB:y()   return 'CBY' end
        --
        CC = CB:extend()
        function CC:__new()
            self.w = self.__module.m - self.__module.n
        end
        function CC:c() return 'CCC' end
        function CC:z() return 'CCZ' end

        -- modules
        MA = MM:extend(CA, CB)
        function MA:new(m, n)
            self.m = m or 0
            self.n = n or 0
        end
        function MA:a() return 'MAA' end
        function MA:x() return 'MAX' end
        --
        MB = MA:extend(CC)
        function MB:new(m, n)
            self.m = m or 0
            self.n = n or 0
        end
        function MB:x()   return 'MBX' end
    end)

    it('should call it\'s own and all mixin functions.', function()
        local ma = MA()
        local mb = MB()

        assert.is.same({ ma:x() }, { 'MAX', 'CAX', '_CX' })
        assert.is.same({ mb:x() }, { 'MBX', '_CX' })
        assert.is.same({ ma:a() }, { 'MAA', 'CAA' })
        assert.is.same({ mb:a() }, { 'MAA', 'CAA' })   -- MB inherits MA:a()
        assert.is.same({ ma:b() }, { 'CBB' })
        assert.is.same({ ma:y() }, { '_CY', 'CBY' })   -- Should obey mixin inheritence!
        assert.has.errors(function() ma:q() end, "attempt to call method 'q' (a nil value)")
    end)

    it('should be able to retrieve properties from self and a mixins.', function()
        local ma = MA(2, 3)

        assert.is.equals(ma.m, 2)
        assert.is.equals(ma.n, 3)
        assert.is.equals(ma.w, -1)     -- from module's mixin
        assert.is.equals(ma.v, 5)      -- from module's mixin
        --TODO:
        -- assert.is.equals(ma._v1, 42)   -- from super-mixin!
    end)

    it('should be able to check equality based on namespace.', function()
        assert.is_false(MA == MB)
        assert.is_true(MA == MA)
    end)
end)