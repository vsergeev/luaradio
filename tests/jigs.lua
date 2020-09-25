---
-- Helper and wrapper functions for unit testing blocks against test vectors.
--
-- @module tests.jigs

local assert = require('luassert')
local busted = require('busted')

---
-- Compare two objects for approximately equality.
--
-- @internal
-- @function assert_approx_equal
-- @tparam object x Expected object
-- @tparam object y Actual object
-- @tparam number epsilon Epsilon for comparison
-- @treturn bool Result
local function assert_approx_equal(x, y, epsilon)
    if (type(x) == "table" or type(x) == "cdata") and x.__index.approx_equal then
        assert.is_true(x:approx_equal(y, epsilon or 0.0))
    elseif type(x) == "number" and type(x) == "number" then
        assert.is_true(math.abs(x - y) < epsilon)
    else
        assert.are.same(x, y)
    end
end

---
-- Compare two vectors.
--
-- @internal
-- @function assert_vector_equal
-- @tparam object x Expected vector
-- @tparam object y Actual vector
-- @tparam number epsilon Epsilon for comparison
-- @treturn bool Result
local function assert_vector_equal(x, y, epsilon)
    assert.is.equal(x.length, y.length)
    assert.is.equal(x.data_type, y.data_type)
    for i=0, x.length-1 do
        assert_approx_equal(x.data[i], y.data[i], epsilon)
    end
end

---
-- Test a block against a set of test vectors.
--
-- @internal
-- @function TestBlock
-- @tparam class block_class Block class to test
-- @tparam array vectors Array of vectors, each vector is a table with
--                       `desc`, `args`, `inputs`, `outputs` keys.
-- @tparam table options Additional options, specifying:
--                       * `epsilon` (number)
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
            input_types[i] = test_vector.inputs[i].data_type
        end

        -- Differentiate the block
        block:differentiate(input_types)

        -- Initialize the block
        block:initialize()

        return block
    end

    busted.describe(block_class.name, function ()
        for i=1, #vectors do
            busted.it("test vector " .. i .. (vectors[i].desc and (" " .. vectors[i].desc) or ""), function ()
                local test_vector = vectors[i]

                ------------------------------------------------------------
                -- Run test once with entire input vectors
                ------------------------------------------------------------

                -- Create the ready-to-go block
                local block = create_block(test_vector)

                -- Compare differentiated type signature with expected output count and types
                assert.is.equal(#block.signature.outputs, #test_vector.outputs)
                for i=1, #test_vector.outputs do
                    assert.is.equal(block:get_output_type(i), test_vector.outputs[i].data_type)
                end

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
                    outputs[i] = test_vector.outputs[i].data_type.vector()
                end

                -- For every sample in the input vectors
                for sample_index = 0, test_vector.inputs[1].length-1 do
                    -- Assemble single sample input vectors
                    local single_sample_inputs = {}
                    for i=1, #test_vector.inputs do
                        single_sample_inputs[i] = test_vector.inputs[i].data_type.vector()
                        single_sample_inputs[i]:append(test_vector.inputs[i].data[sample_index])
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

---
-- Test a source block against a set of test vectors.
--
-- @internal
-- @function TestSourceBlock
-- @tparam class block_class Block class to test
-- @tparam array vectors Array of vectors, each vector is a table with
--                       `desc`, `args`, `outputs` keys.
-- @tparam table options Additional options, specifying:
--                       * `epsilon` (number)
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
            busted.it("test vector " .. i .. (vectors[i].desc and (" " .. vectors[i].desc) or ""), function ()
                local test_vector = vectors[i]

                -- Run block until we have enough sufficient output to compare
                -- to the test vector.

                -- Create the ready-to-go block
                local block = create_block(test_vector)

                -- Compare type signature with expected output count and types
                assert.is.equal(#block.signature.outputs, #test_vector.outputs)
                for i=1, #test_vector.outputs do
                    assert.is.equal(block.signature.outputs[i].data_type, test_vector.outputs[i].data_type)
                end

                -- Create array for collected outputs
                local collected_outputs = {}
                for i=1, #test_vector.outputs do
                    collected_outputs[i] = test_vector.outputs[i].data_type.vector(0)
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

---
-- Test a composite block against a set of test vectors.
--
-- @internal
-- @function TestCompositeBlock
-- @tparam class block_class Block class to test
-- @tparam array vectors Array of vectors, each vector is a table with
--                       `desc`, `args`, `inputs`, `outputs` keys.
-- @tparam table options Additional options, specifying:
--                       * `epsilon` (number)
local function TestCompositeBlock(block_class, vectors, options)
    options = options or {}

    local radio = require('radio')
    local ffi = require('ffi')
    local buffer = require('tests.buffer')

    busted.describe(block_class.name, function ()
        for i=1, #vectors do
            busted.it("test vector " .. i .. (vectors[i].desc and (" " .. vectors[i].desc) or ""), function ()
                local test_vector = vectors[i]

                -- Build raw file sources for inputs
                local sources = {}
                local src_fds = {}
                for i = 1, #test_vector.inputs do
                    src_fds[i] = buffer.open(ffi.string(test_vector.inputs[i].data_type.serialize(test_vector.inputs[i])))
                    sources[i] = radio.RawFileSource(src_fds[i], test_vector.inputs[i].data_type, 2.0)
                end

                -- Build raw file sinks for inputs
                local sinks = {}
                local snk_fds = {}
                for i = 1, #test_vector.outputs do
                    snk_fds[i] = buffer.open()
                    sinks[i] = radio.RawFileSink(snk_fds[i])
                end

                -- Instantiate the composite block
                local block = block_class(unpack(test_vector.args or {}))

                -- Create a top block
                local top = radio.CompositeBlock()

                -- Connect inputs and outputs
                for i = 1, #test_vector.inputs do
                    top:connect(sources[i], 'out', block, block.inputs[i].name)
                end
                for i = 1, #test_vector.outputs do
                    top:connect(block, block.outputs[i].name, sinks[i], 'in')
                end

                -- Run the top block
                top:run(false)

                -- Deserialize outputs
                local outputs = {}
                for i = 1, #test_vector.outputs do
                    buffer.rewind(snk_fds[i])
                    local buf = buffer.read(snk_fds[i], test_vector.outputs[i].size)
                    outputs[i] = test_vector.outputs[i].data_type.deserialize(buf, #buf)
                end

                -- Compare outputs with expected outputs
                for i=1, #outputs do
                    assert_vector_equal(outputs[i], test_vector.outputs[i], options.epsilon)
                end

                -- Close source and sink fds
                for i = 1, #test_vector.inputs do
                    buffer.close(src_fds[i])
                end
                for i = 1, #test_vector.outputs do
                    buffer.close(snk_fds[i])
                end
            end)
        end
    end)
end

return {TestBlock = TestBlock, TestCompositeBlock = TestCompositeBlock, TestSourceBlock = TestSourceBlock, assert_approx_equal = assert_approx_equal, assert_vector_equal = assert_vector_equal}
