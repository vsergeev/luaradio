local util = require('radio.core.util')

describe("table and array utilities", function ()
    it("table_length()", function ()
        assert.is.equal(0, util.table_length({}))
        assert.is.equal(3, util.table_length({foo = 'bar', bar = nil, abc = true, def = 1}))
        assert.is.equal(5, util.table_length({1, 2, 3, 4, 5}))
    end)

    it("table_keys()", function ()
        assert.is.same(util.table_keys({}), {})

        local keys = util.table_keys({[4] = "abc", [5] = "def", [6] = "ghi"})
        table.sort(keys)
        assert.is.same(keys, {4, 5, 6})

        local keys = util.table_keys({a = 4, b = 5, c = 6})
        table.sort(keys)
        assert.is.same(keys, {"a", "b", "c"})
    end)

    it("table_copy()", function ()
        local x = {foo = 'bar', bar = nil, abc = true, def = 1}
        local y = util.table_copy(x)

        assert.is_true(x ~= y)
        assert.is.same(y, x)
    end)

    it("table_extend()", function ()
        assert.is.same(util.table_extend({}, {}), {})
        assert.is.same(util.table_extend({a = 1}, {}), {a = 1})
        assert.is.same(util.table_extend({}, {a = 1}), {a = 1})
        assert.is.same(util.table_extend({a = 1}, {b = 2}), {a = 1, b = 2})
        assert.is.same(util.table_extend({a = 1, c = {4, 5, 6}}, {b = 2}), {a = 1, b = 2, c = {4, 5, 6}})
        assert.is.same(util.table_extend({1, 2, 3, a = 1}, {4, 5, 6, b = 2}), {4, 5, 6, a = 1, b = 2})
    end)

    it("array_concat()", function ()
        assert.is.same(util.array_concat({}, {}), {})
        assert.is.same(util.array_concat({1, 2}, {}), {1, 2})
        assert.is.same(util.array_concat({}, {1, 2}), {1, 2})
        assert.is.same(util.array_concat({1, 2}, {3, 4}), {1, 2, 3, 4})
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

    it("array_map()", function ()
        assert.is.same(util.array_map({1, 2, 3}, function (e) return e end), {1, 2, 3})
        assert.is.same(util.array_map({1, 2, 3}, function (e) return 0 end), {0, 0, 0})
        assert.is.same(util.array_map({1, 2, 3}, function (e) return e * e end), {1, 4, 9})
        assert.is.same(util.array_map({"a", "b", "c"}, function (e) return e .. e end), {"aa", "bb", "cc"})
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

    it("parse_args()", function ()
        -- Typical usage
        local options = {
            {"aaa", "a", false},
            {"bbb", "b", true},
            {"ccc", "c", true},
            {"qux", "", false},
        }
        local parsed = util.parse_args({"-a", "-b", "42", "--ccc", "84", "--qux", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42", ccc = "84", qux = true,
                                    [1] = "x", [2] = "y", [3] = "z"})

        -- Positional encountered
        local parsed = util.parse_args({"-a", "-b", "42", "--ccc", "84", "foo", "--qux", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42", ccc = "84",
                                    [1] = "foo", [2] = "--qux", [3] = "x", [4] = "y", [5] = "z"})

        -- Positional encountered
        local parsed = util.parse_args({"-a", "-b", "42", "--ccc", "84", "-", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42", ccc = "84",
                                    [1] = "-", [2] = "x", [3] = "y", [4] = "z"})

        -- Option argument with leading dash
        local parsed = util.parse_args({"-a", "-b", "42", "--ccc", "-123", "-", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42", ccc = "-123",
                                    [1] = "-", [2] = "x", [3] = "y", [4] = "z"})

        -- Unknown long option stops parsing
        local parsed = util.parse_args({"-a", "-b", "42", "--ccc", "84", "--ddd", "--qux", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42", ccc = "84",
                                    [1] = "--ddd", [2] = "--qux", [3] = "x", [4] = "y", [5] = "z"})

        -- Unknown short option short stops parsing
        local parsed = util.parse_args({"-a", "-b", "42", "-d", "--ccc", "84", "--qux", "x", "y", "z"}, options)
        assert.is_same(parsed, {aaa = true, bbb = "42",
                                    [1] = "-d", [2] = "--ccc", [3] = "84", [4] = "--qux", [5] = "x", [6] = "y", [7] = "z"})

        -- Missing option argument due to end of arguments
        assert.has_error(function () util.parse_args({"-a", "-b", "42", "--ccc"}, options) end)

        -- Typical usage with two parsers
        local options2 = {
            {"ddd", "d", false},
            {"eee", "e", true},
            {"fff", "f", false},
        }
        local parsed1 = util.parse_args({"-a", "-b", "42", "--ccc", "84", "--qux", "-d", "--eee", "168", "--fff", "x", "y", "z"}, options)
        assert.is_same(parsed1, {aaa = true, bbb = "42", ccc = "84", qux = true,
                                    [1] = "-d", [2] = "--eee", [3] = "168", [4] = "--fff", [5] = "x", [6] = "y", [7] = "z"})
        local parsed2 = util.parse_args(parsed1, options2)
        assert.is_same(parsed2, {ddd = true, eee = "168", fff = true,
                                    [1] = "x", [2] = "y", [3] = "z"})
    end)
end)
