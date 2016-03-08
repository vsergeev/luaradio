describe("radio namespacing", function ()
    it("does not introduce global variables", function ()
        local count_before_import = 0
        for k,v in pairs(_G) do
            count_before_import = count_before_import + 1
        end

        local radio = require('radio')

        local count_after_import = 0
        for k,v in pairs(_G) do
            count_after_import = count_after_import + 1
        end

        assert.is.equal(count_after_import, count_before_import)
    end)
end)
