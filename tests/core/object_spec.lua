local object = require('radio.core.object')
local types = require('radio.types')

local Foo = object.class_factory()

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

local Bar = object.class_factory(Foo)

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

local Baz = object.class_factory()

function Baz.new()
    return setmetatable({}, Baz)
end

local Qux = object.class_factory(Baz)

function Qux.new()
    return setmetatable({}, Qux)
end

local Norf = object.class_factory(Qux)

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
        assert.is_true(object.isinstanceof("foo", "string"))
        assert.is_false(object.isinstanceof(5, "string"))
        assert.is_false(object.isinstanceof(true, "string"))
        assert.is_false(object.isinstanceof({}, "string"))
        assert.is_false(object.isinstanceof(nil, "string"))

        assert.is_true(object.isinstanceof(5, "number"))
        assert.is_false(object.isinstanceof("foo", "number"))
        assert.is_false(object.isinstanceof(true, "number"))
        assert.is_false(object.isinstanceof({}, "number"))
        assert.is_false(object.isinstanceof(nil, "number"))

        assert.is_true(object.isinstanceof(true, "boolean"))
        assert.is_false(object.isinstanceof("foo", "boolean"))
        assert.is_false(object.isinstanceof(5, "boolean"))
        assert.is_false(object.isinstanceof({}, "boolean"))
        assert.is_false(object.isinstanceof(nil, "boolean"))

        assert.is_true(object.isinstanceof({}, "table"))
        assert.is_false(object.isinstanceof("foo", "table"))
        assert.is_false(object.isinstanceof(5, "table"))
        assert.is_false(object.isinstanceof(true, "table"))
        assert.is_false(object.isinstanceof(nil, "table"))

        assert.is_true(object.isinstanceof(nil, "nil"))
        assert.is_false(object.isinstanceof("foo", "nil"))
        assert.is_false(object.isinstanceof(5, "nil"))
        assert.is_false(object.isinstanceof(true, "nil"))
        assert.is_false(object.isinstanceof({}, "nil"))
    end)

    it("isinstanceof() classes", function ()
        local a = Foo(5)
        local b = Bar(1, 2)
        local c = Baz()
        local d = Qux()
        local e = Norf()

        assert.is_true(object.isinstanceof(a, Foo))
        assert.is_false(object.isinstanceof(a, Bar))
        assert.is_false(object.isinstanceof(a, Baz))
        assert.is_false(object.isinstanceof(a, Qux))
        assert.is_false(object.isinstanceof(a, Norf))

        assert.is_true(object.isinstanceof(b, Foo))
        assert.is_true(object.isinstanceof(b, Bar))
        assert.is_false(object.isinstanceof(b, Baz))
        assert.is_false(object.isinstanceof(b, Qux))
        assert.is_false(object.isinstanceof(b, Norf))

        assert.is_false(object.isinstanceof(c, Foo))
        assert.is_false(object.isinstanceof(c, Bar))
        assert.is_true(object.isinstanceof(c, Baz))
        assert.is_false(object.isinstanceof(c, Qux))
        assert.is_false(object.isinstanceof(c, Norf))

        assert.is_false(object.isinstanceof(d, Foo))
        assert.is_false(object.isinstanceof(d, Bar))
        assert.is_true(object.isinstanceof(d, Baz))
        assert.is_true(object.isinstanceof(d, Qux))
        assert.is_false(object.isinstanceof(d, Norf))

        assert.is_false(object.isinstanceof(e, Foo))
        assert.is_false(object.isinstanceof(e, Bar))
        assert.is_true(object.isinstanceof(e, Baz))
        assert.is_true(object.isinstanceof(e, Qux))
        assert.is_true(object.isinstanceof(e, Norf))
    end)

    it("isinstanceof() cdata types", function ()
        assert.is_true(object.isinstanceof(types.ComplexFloat32Type(1, 2), types.ComplexFloat32Type))
        assert.is_true(object.isinstanceof(types.ComplexFloat32Type(1, 2), types.CStructType))
        assert.is_false(object.isinstanceof(types.ComplexFloat32Type(2), "number"))
        assert.is_false(object.isinstanceof(types.Float32Type(2), types.ComplexFloat32Type))
        assert.is_false(object.isinstanceof(5, types.ComplexFloat32Type))
        assert.is_false(object.isinstanceof(5, types.CStructType))
        assert.is_false(object.isinstanceof({}, types.ComplexFloat32Type))
        assert.is_false(object.isinstanceof({}, types.CStructType))

        assert.is_true(object.isinstanceof(types.Float32Type(1), types.Float32Type))
        assert.is_true(object.isinstanceof(types.Float32Type(1), types.CStructType))
        assert.is_false(object.isinstanceof(types.Float32Type(2), "number"))
        assert.is_false(object.isinstanceof(types.ComplexFloat32Type(1, 2), types.Float32Type))
        assert.is_false(object.isinstanceof(5, types.Float32Type))
        assert.is_false(object.isinstanceof({}, types.Float32Type))
    end)
end)
