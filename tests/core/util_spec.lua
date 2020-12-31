local util = require('radio.core.util')

describe("table and array utilities", function ()
    it("table_length()", function ()
        assert.is.equal(0, util.table_length({}))
        assert.is.equal(3, util.table_length({foo = 'bar', bar = nil, abc = true, def = 1}))
        assert.is.equal(5, util.table_length({1, 2, 3, 4, 5}))
    end)

    it("table_copy()", function ()
        local x = {foo = 'bar', bar = nil, abc = true, def = 1}
        local y = util.table_copy(x)

        assert.is_true(x ~= y)
        assert.is.same(y, x)
    end)

    it("array_flatten()", function ()
        assert.is.same(util.array_flatten({}), {})
        assert.is.same(util.array_flatten({1, 2, 3}), {1, 2, 3})
        assert.is.same(util.array_flatten({1, {2, {3}}}), {1, 2, 3})
        assert.is.same(util.array_flatten({1, {2}, {3, {{{{4}}}}, 5, {6, 7, {8}}}}), {1, 2, 3, 4, 5, 6, 7, 8})

        -- Test depth
        assert.is.same(util.array_flatten({1, {2, {3}}}, 0), {1, {2, {3}}})
        assert.is.same(util.array_flatten({1, {2, {3}}}, 1), {1, 2, {3}})
        assert.is.same(util.array_flatten({1, {2, {3}}}, 2), {1, 2, 3})
        assert.is.same(util.array_flatten({1, {2, {3}}}, 3), {1, 2, 3})
        assert.is.same(util.array_flatten({1, {2}, {3, {4, {5}}}}, 1), {1, 2, 3, {4, {5}}})
    end)

    it("array_exists()", function ()
        local x = {'bar', 'foo', 123, true}

        assert.is_true(util.array_exists(x, 'bar'))
        assert.is_true(util.array_exists(x, 'foo'))
        assert.is_true(util.array_exists(x, 123))
        assert.is_true(util.array_exists(x, true))
        assert.is_false(util.array_exists(x, false))
        assert.is_false(util.array_exists(x, 'abc'))
    end)

    it("array_search()", function ()
        local x = {}
        local y = {}
        local arr = {'bar', 'foo', 123, false, x, y}

        assert.is.equal('bar', util.array_search(arr, function (x) return x == 'bar' end))
        assert.is.equal(123, util.array_search(arr, function (x) return type(x) == 'number' end))
        assert.is.equal(nil, util.array_search(arr, function (x) return x == 456 end))
        assert.is.equal(x, util.array_search(arr, function (e) return e == x end))
    end)

    it("array_all()", function ()
        local x = {1, 2, 3, 4, 5}
        local y = {2, 4, 6, 8, 10}
        local z = {1, 3, 5, 7, 9}

        assert.is_true(util.array_all(x, function (e) return type(e) == 'number' end))
        assert.is_false(util.array_all(x, function (e) return (e % 2) == 0 end))
        assert.is_true(util.array_all(y, function (e) return (e % 2) == 0 end))
        assert.is_false(util.array_all(z, function (e) return (e % 2) == 0 end))
        assert.is_false(util.array_all(x, function (e) return (e % 2) == 1 end))
        assert.is_false(util.array_all(y, function (e) return (e % 2) == 1 end))
        assert.is_true(util.array_all(z, function (e) return (e % 2) == 1 end))
    end)

    it("array_equals()", function ()
        local x = {1, 2, 3, 4, 5}
        local y = {1, 2, 3, 4}
        local z = {1, 2, 3, 4, 5}
        local w = {1, 2, 3, 4, 6}

        assert.is_false(util.array_equals(x, y))
        assert.is_false(util.array_equals(x, w))
        assert.is_true(util.array_equals(x, z))
    end)

    it("array_find()", function ()
        local x = {5, 4, 3, 2, 1}

        assert.is.equal(1, util.array_find(x, 5))
        assert.is.equal(2, util.array_find(x, 4))
        assert.is.equal(3, util.array_find(x, 3))
        assert.is.equal(4, util.array_find(x, 2))
        assert.is.equal(5, util.array_find(x, 1))
        assert.is.equal(nil, util.array_find(x, 0))
        assert.is.equal(nil, util.array_find(x, 6))
    end)
end)
