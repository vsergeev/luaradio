local class = require('radio.core.class')
local types = require('radio.types')

local Foo = class.factory()

function Foo.new(a)
    local self = setmetatable({}, Foo)
    self.a = a
    return self
end

function Foo:get_a()
    return self.a
end

function Foo:bark()
    return "woof"
end

local Bar = class.factory(Foo)

function Bar.new(a, b)
    local self = setmetatable({}, Bar)
    self.a = a
    self.b = b
    return self
end

function Bar:get_b()
    return self.b
end

function Bar:bark()
    return "lol"
end

function Bar:purr()
    return "meow"
end

local Baz = class.factory()

function Baz.new()
    return setmetatable({}, Baz)
end

local Qux = class.factory(Baz)

function Qux.new()
    return setmetatable({}, Qux)
end

local Norf = class.factory(Qux)

function Norf.new()
    return setmetatable({}, Norf)
end

describe("oo helpers", function ()
    it("inheritance", function ()
        local a = Foo(5)
        local b = Bar(1, 2)

        assert.is.equal("woof", a:bark())
        assert.is.equal(nil, a.purr)
        assert.is.equal(5, a:get_a())

        assert.is.equal("lol", b:bark())
        assert.is.equal("meow", b:purr())
        assert.is.equal(1, b:get_a())
        assert.is.equal(2, b:get_b())
    end)

    it("isinstanceof() basic types", function ()
        assert.is_true(class.isinstanceof("foo", "string"))
        assert.is_false(class.isinstanceof(5, "string"))
        assert.is_false(class.isinstanceof(true, "string"))
        assert.is_false(class.isinstanceof({}, "string"))
        assert.is_false(class.isinstanceof(nil, "string"))

        assert.is_true(class.isinstanceof(5, "number"))
        assert.is_false(class.isinstanceof("foo", "number"))
        assert.is_false(class.isinstanceof(true, "number"))
        assert.is_false(class.isinstanceof({}, "number"))
        assert.is_false(class.isinstanceof(nil, "number"))

        assert.is_true(class.isinstanceof(true, "boolean"))
        assert.is_false(class.isinstanceof("foo", "boolean"))
        assert.is_false(class.isinstanceof(5, "boolean"))
        assert.is_false(class.isinstanceof({}, "boolean"))
        assert.is_false(class.isinstanceof(nil, "boolean"))

        assert.is_true(class.isinstanceof({}, "table"))
        assert.is_false(class.isinstanceof("foo", "table"))
        assert.is_false(class.isinstanceof(5, "table"))
        assert.is_false(class.isinstanceof(true, "table"))
        assert.is_false(class.isinstanceof(nil, "table"))

        assert.is_true(class.isinstanceof(nil, "nil"))
        assert.is_false(class.isinstanceof("foo", "nil"))
        assert.is_false(class.isinstanceof(5, "nil"))
        assert.is_false(class.isinstanceof(true, "nil"))
        assert.is_false(class.isinstanceof({}, "nil"))
    end)

    it("isinstanceof() classes", function ()
        local a = Foo(5)
        local b = Bar(1, 2)
        local c = Baz()
        local d = Qux()
        local e = Norf()

        assert.is_true(class.isinstanceof(a, Foo))
        assert.is_false(class.isinstanceof(a, Bar))
        assert.is_false(class.isinstanceof(a, Baz))
        assert.is_false(class.isinstanceof(a, Qux))
        assert.is_false(class.isinstanceof(a, Norf))

        assert.is_true(class.isinstanceof(b, Foo))
        assert.is_true(class.isinstanceof(b, Bar))
        assert.is_false(class.isinstanceof(b, Baz))
        assert.is_false(class.isinstanceof(b, Qux))
        assert.is_false(class.isinstanceof(b, Norf))

        assert.is_false(class.isinstanceof(c, Foo))
        assert.is_false(class.isinstanceof(c, Bar))
        assert.is_true(class.isinstanceof(c, Baz))
        assert.is_false(class.isinstanceof(c, Qux))
        assert.is_false(class.isinstanceof(c, Norf))

        assert.is_false(class.isinstanceof(d, Foo))
        assert.is_false(class.isinstanceof(d, Bar))
        assert.is_true(class.isinstanceof(d, Baz))
        assert.is_true(class.isinstanceof(d, Qux))
        assert.is_false(class.isinstanceof(d, Norf))

        assert.is_false(class.isinstanceof(e, Foo))
        assert.is_false(class.isinstanceof(e, Bar))
        assert.is_true(class.isinstanceof(e, Baz))
        assert.is_true(class.isinstanceof(e, Qux))
        assert.is_true(class.isinstanceof(e, Norf))
    end)

    it("isinstanceof() cdata types", function ()
        assert.is_true(class.isinstanceof(types.ComplexFloat32(1, 2), types.ComplexFloat32))
        assert.is_true(class.isinstanceof(types.ComplexFloat32(1, 2), types.CStructType))
        assert.is_false(class.isinstanceof(types.ComplexFloat32(2), "number"))
        assert.is_false(class.isinstanceof(types.Float32(2), types.ComplexFloat32))
        assert.is_false(class.isinstanceof(5, types.ComplexFloat32))
        assert.is_false(class.isinstanceof(5, types.CStructType))
        assert.is_false(class.isinstanceof({}, types.ComplexFloat32))
        assert.is_false(class.isinstanceof({}, types.CStructType))

        assert.is_true(class.isinstanceof(types.Float32(1), types.Float32))
        assert.is_true(class.isinstanceof(types.Float32(1), types.CStructType))
        assert.is_false(class.isinstanceof(types.Float32(2), "number"))
        assert.is_false(class.isinstanceof(types.ComplexFloat32(1, 2), types.Float32))
        assert.is_false(class.isinstanceof(5, types.Float32))
        assert.is_false(class.isinstanceof({}, types.Float32))
    end)
end)
