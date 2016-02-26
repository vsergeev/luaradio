local assert = require('luassert')
local busted = require('busted')

local function assert_approx_equal(x, y, epsilon)
    if (type(x) == "table" or type(x) == "cdata") and x.__index.approx_equal then
        assert.is_true(x:approx_equal(y, epsilon or 0.0))
    elseif type(x) == "number" and type(x) == "number" then
        assert.is_true(math.abs(x - y) < epsilon)
    else
        assert.are.equal(x, y)
    end
end

local function assert_vector_equal(x, y, epsilon)
    assert.is.equal(x.length, y.length)
    assert.is.equal(x.type, y.type)
    for i=0, x.length-1 do
        assert_approx_equal(x.data[i], y.data[i], epsilon)
    end
end

local function TestBlock(block_class, vectors, options)
    options = options or {}

    -- Instantiate, differentiate, and initialize the block
    local function create_block(test_vector)
        local args = test_vector.args or {}

        local block = block_class(unpack(args))

        -- Monkey-patch get_rate() to return normalized frequency
        block.get_rate = function (self) return 2.0 end

        -- Assemble input types
        local input_types = {}
        for i=1, #test_vector.inputs do
            input_types[i] = test_vector.inputs[i].type
        end

        -- Differentiate the block
        block:differentiate(input_types)

        -- Initialize the block
        block:initialize()

        return block
    end

    busted.describe(block_class.name, function ()
        for i=1, #vectors do
            busted.it("test vector " .. i, function ()
                local test_vector = vectors[i]

                ------------------------------------------------------------
                -- Run test once with entire input vectors
                ------------------------------------------------------------

                -- Create the ready-to-go block
                local block = create_block(test_vector)

                -- Run process
                local outputs = {block:process(unpack(test_vector.inputs))}

                -- Compare outputs with expected outputs
                assert.is_true(#outputs == #test_vector.outputs)
                for i=1, #outputs do
                    assert_vector_equal(outputs[i], test_vector.outputs[i], options.epsilon)
                end

                ------------------------------------------------------------
                -- Run test once with sample-by-sample input vectors
                ------------------------------------------------------------

                -- Create the ready-to-go block
                local block = create_block(test_vector)

                -- Create an empty vector for each output
                local outputs = {}
                for i = 1, #test_vector.outputs do
                    outputs[i] = test_vector.outputs[i].type.vector()
                end

                -- For every sample in the input vectors
                for sample_index = 0, test_vector.inputs[1].length-1 do
                    -- Assemble single sample input vectors
                    local single_sample_inputs = {}
                    for i=1, #test_vector.inputs do
                        local data_type = test_vector.inputs[i].type
                        local sample = test_vector.inputs[i].data[sample_index]
                        single_sample_inputs[i] = data_type.vector_from_array({sample})
                    end

                    -- Run process on single sample input vectors
                    local single_sample_outputs = {block:process(unpack(single_sample_inputs))}

                    -- Append single sample output vectors to our outputs
                    for i=1, #test_vector.outputs do
                        for j = 0, single_sample_outputs[i].length-1 do
                            outputs[i]:append(single_sample_outputs[i].data[j])
                        end
                    end
                end

                -- Compare outputs with expected outputs
                assert.is_true(#outputs == #test_vector.outputs)
                for i=1, #outputs do
                    assert_vector_equal(outputs[i], test_vector.outputs[i], options.epsilon)
                end
            end)
        end
    end)
end

local function TestSourceBlock(block_class, vectors, options)
    options = options or {}

    -- Instantiate, differentiate, and initialize the block
    local function create_block(test_vector)
        local args = test_vector.args or {}

        local block = block_class(unpack(args))

        -- Differentiate the block
        block:differentiate({})

        -- Initialize the block
        block:initialize()

        return block
    end

    busted.describe(block_class.name, function ()
        for i=1, #vectors do
            busted.it("test vector " .. i, function ()
                local test_vector = vectors[i]

                -- Run block until we have enough sufficient output to compare
                -- to the test vector.

                -- Create the ready-to-go block
                local block = create_block(test_vector)

                -- Create array for collected outputs
                local collected_outputs = {}
                for i=1, #test_vector.outputs do
                    collected_outputs[i] = test_vector.outputs[i].type.vector(0)
                end

                -- Run process
                while collected_outputs[1].length < test_vector.outputs[1].length do
                    local outputs = {block:process()}
                    for i=1, #outputs do
                        for j=0, outputs[i].length-1 do
                            collected_outputs[i]:append(outputs[i].data[j])
                        end
                    end
                end

                -- Compare outputs with expected outputs
                for i=1, #collected_outputs do
                    collected_outputs[i]:resize(test_vector.outputs[i].length)
                    assert_vector_equal(collected_outputs[i], test_vector.outputs[i], options.epsilon)
                end
            end)
        end
    end)
end

return {TestBlock = TestBlock, TestSourceBlock = TestSourceBlock, assert_approx_equal = assert_approx_equal, assert_vector_equal = assert_vector_equal}
