--
-- dbg = require 'debugger'
-- dbg.auto_where = 2
--
package.path = "../?.lua;" .. package.path
require 'busted.runner'()
--

describe('Modern - Reflection Tests', function()
    local MM = require 'modern'
    local MA, MB
    local CA, CB, CC, CD

    setup(function()
        -- components
        CA = MM:extend()
        CB = CA:extend()
        CC = CB:extend()
        CD = CB:extend()
        -- modules
        MA = MM:extend(CB, CC)
        function MA:new() end
        MB = MA:extend(CD)
        function MB:new() end
    end)

    it('should pass `is` reflection for inheritance tests', function()
        assert.is_true(MA:is(MM))
        assert.is_true(MB:is(MA))
        assert.is_true(MB:is(MM))
        assert.is_true(MB:is(MA))
        assert.is_false(MA:is(MB))
    end)

    it('should pass `has` reflection for mixin inclusion tests', function()
        assert.is_true(MA:has(CB))
        assert.is_true(MA:has(CC))
        assert.is_false(MA:has(CD))
        assert.has_error(
            function() MA:has(CA) end,
            "Module you are comparing is not a Mixin."
        )
    end)

    it('should pass `super` reflection for identifying super module', function()
        assert.is.equal(MB:super(), MA)
        assert.is_not.equal(MB:super(), MM)
    end)

    it('should be assigned the correct namespace based on inheritance', function()
        assert.is.equal(MM.__namespace, 'Modern')
        assert.is.equal(MA.__namespace, 'Modern\\MA')
        assert.is.equal(MB.__namespace, 'Modern\\MA\\MB')
        assert.is.equal(CD.__namespace, 'Modern\\CA\\CB\\CD')
    end)

    it('should recognize it\'s parent module , if a mixin', function()
        assert.same(CB.__module, MA)
        assert.same(CC.__module, MA)
        assert.same(CD.__module, MB)
        assert.is_false(CA.__module)
    end)

    it('should recognize mixins only assigned to self', function()
        assert.is.same(MA.__mixins, { CB = CB, CC = CC })
        assert.is.same(MB.__mixins, { CD = CD })
        assert.is.same(MM.__mixins, { })
    end)
end)
