local radio = require('radio')
local class = require('radio.core.class')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')

describe("block", function ()
    it("class properties", function ()
        local TestBlock = block.factory("TestBlock")
        assert.is.equal("TestBlock", TestBlock.name)
    end)

    it("instantiation", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate(a, b)
            self.a = a
            self.b = b
        end

        local blk = TestBlock(1, 2)
        assert.is.equal(1, blk.a)
        assert.is.equal(2, blk.b)

        -- No type signatures registered
        assert.is_true(#blk.signatures == 0)
        assert.is_true(blk.inputs == nil)
        assert.is_true(blk.outputs == nil)
    end)

    it("type signatures", function ()
        local TestBlock = block.factory("TestBlock")

        -- Basic type signature
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("in1", radio.types.Float32), block.Input("in2", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        local blk = TestBlock()
        assert.is.equal(2, #blk.signatures)
        assert.is.equal(2, #blk.inputs)
        assert.is.equal(1, #blk.outputs)
        assert.is_true(class.isinstanceof(blk.inputs[1], pipe.InputPort))
        assert.is_true(class.isinstanceof(blk.inputs[2], pipe.InputPort))
        assert.is_true(class.isinstanceof(blk.outputs[1], pipe.OutputPort))

        -- Test invalid input descriptor
        function TestBlock:instantiate()
            self:add_type_signature({block.Output("in", radio.types.Float32)}, {})
        end
        assert.has_error(function () TestBlock() end)

        -- Test invalid output descriptor
        function TestBlock:instantiate()
            self:add_type_signature({}, {block.Input("out", radio.types.Float32)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched number of inputs error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched number of outputs error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.Float32), block.Output("out2", radio.types.Float32)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched inputs name error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("foo", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched outputs name error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("foo", radio.types.Float32)})
        end
        assert.has_error(function () TestBlock() end)
    end)

    it("type differentiation", function ()
        local TestBlock = block.factory("TestBlock")

        -- Test differentiation
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.Float32)},
                                    {block.Output("out", radio.types.Float32)})
            self:add_type_signature({block.Input("in1", radio.types.Float32), block.Input("in2", radio.types.Byte)},
                                    {block.Output("out", radio.types.Byte)})
            self:add_type_signature({block.Input("in1", radio.types.Bit), block.Input("in2", radio.types.Byte)},
                                    {block.Output("out", radio.types.Byte)})
            self:add_type_signature({block.Input("in1", radio.types.Bit), block.Input("in2", radio.types.Bit)},
                                    {block.Output("out", radio.types.Bit)})
        end

        local blk = TestBlock()

        -- Test getting input/output types before differentiation
        assert.has_error(function () blk:get_input_type() end)
        assert.has_error(function () blk:get_output_type() end)

        -- Test valid differentiations
        blk:differentiate({radio.types.ComplexFloat32, radio.types.Float32})
        assert.is.equal(blk.signatures[1], blk.signature)
        assert.is.same(radio.types.ComplexFloat32, blk:get_input_type(1))
        assert.is.same(radio.types.Float32, blk:get_input_type(2))
        assert.is.same(radio.types.Float32, blk:get_output_type(1))

        blk:differentiate({radio.types.Float32, radio.types.Byte})
        assert.is.equal(blk.signatures[2], blk.signature)
        assert.is.same(radio.types.Float32, blk:get_input_type(1))
        assert.is.same(radio.types.Byte, blk:get_input_type(2))
        assert.is.same(radio.types.Byte, blk:get_output_type(1))

        blk:differentiate({radio.types.Bit, radio.types.Byte})
        assert.is.equal(blk.signatures[3], blk.signature)
        assert.is.same(radio.types.Bit, blk:get_input_type(1))
        assert.is.same(radio.types.Byte, blk:get_input_type(2))
        assert.is.same(radio.types.Byte, blk:get_output_type(1))

        blk:differentiate({radio.types.Bit, radio.types.Bit})
        assert.is.equal(blk.signatures[4], blk.signature)
        assert.is.same(radio.types.Bit, blk:get_input_type(1))
        assert.is.same(radio.types.Bit, blk:get_input_type(2))
        assert.is.same(radio.types.Bit, blk:get_output_type(1))

        -- Test invalid differentiations
        assert.has_error(function () blk:differentiate({}) end)
        assert.has_error(function () blk:differentiate({radio.types.ComplexFloat32}) end)
        assert.has_error(function () blk:differentiate({radio.types.Float32}) end)
        assert.has_error(function () blk:differentiate({radio.types.Byte}) end)
        assert.has_error(function () blk:differentiate({radio.types.Bit}) end)
        assert.has_error(function () blk:differentiate({radio.types.ComplexFloat32, radio.types.ComplexFloat32}) end)
        assert.has_error(function () blk:differentiate({radio.types.Float32, radio.types.Bit}) end)
        assert.has_error(function () blk:differentiate({radio.types.Byte, radio.types.Bit}) end)
        assert.has_error(function () blk:differentiate({radio.types.Byte, radio.types.Byte}) end)

        -- Test custom type signature dependent initialize and process functions

        function TestBlock:initialize_float() end
        function TestBlock:initialize_integer() end
        function TestBlock:process_float() end
        function TestBlock:process_integer() end
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {}, TestBlock.process_float, TestBlock.initialize_float)
            self:add_type_signature({block.Input("in", radio.types.Byte)}, {}, TestBlock.process_integer, TestBlock.initialize_integer)
            self:add_type_signature({block.Input("in", radio.types.Bit)}, {})
        end

        local blk = TestBlock()

        blk:differentiate({radio.types.Float32})
        assert.is.equal(TestBlock.initialize_float, blk.initialize)
        assert.is.equal(TestBlock.process_float, blk.process)
        assert.is.same(radio.types.Float32, blk:get_input_type())
        assert.is.same(nil, blk:get_output_type())

        blk:differentiate({radio.types.Byte})
        assert.is.equal(TestBlock.initialize_integer, blk.initialize)
        assert.is.equal(TestBlock.process_integer, blk.process)
        assert.is.same(radio.types.Byte, blk:get_input_type())
        assert.is.same(nil, blk:get_output_type())

        blk:differentiate({radio.types.Bit})
        assert.is.equal(TestBlock.initialize, blk.initialize)
        assert.is.equal(TestBlock.process, blk.process)
        assert.is.same(radio.types.Bit, blk:get_input_type())
        assert.is.same(nil, blk:get_output_type())

        -- Test source differentiation

        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.Float32)})
        end

        local blk = TestSource()
        blk:differentiate({})
        assert.is.equal(blk.signatures[1], blk.signature)
        assert.is.same(nil, blk:get_input_type())
        assert.is.same(radio.types.Float32, blk:get_output_type())

        -- Test function-based type differentiation

        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", function (type) return (type % 2) == 0 end)}, {})
            self:add_type_signature({block.Input("in", function (type) return (type % 2) == 1 end)}, {})
        end

        local blk = TestBlock()

        blk:differentiate({0})
        assert.is.equal(blk.signatures[1], blk.signature)

        blk:differentiate({1})
        assert.is.equal(blk.signatures[2], blk.signature)

        blk:differentiate({2})
        assert.is.equal(blk.signatures[1], blk.signature)

        blk:differentiate({3})
        assert.is.equal(blk.signatures[2], blk.signature)

        -- Test copying input type to output type

        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", function (type) return true end)}, {block.Output("out", "copy")})
        end

        local blk = TestBlock()

        blk:differentiate({radio.types.Float32})
        assert.is.same(radio.types.Float32, blk:get_input_type())
        assert.is.same(radio.types.Float32, blk:get_output_type())

        blk:differentiate({radio.types.Byte})
        assert.is.same(radio.types.Byte, blk:get_input_type())
        assert.is.same(radio.types.Byte, blk:get_output_type())
    end)

    it("rate propagation", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.Float32)})
        end

        -- Source blocks should define rate

        local blk = TestSource()

        -- Test getting rate before differentiation error
        assert.has_errors(function () blk:get_rate() end)

        blk:differentiate({})

        -- Test undefined get_rate() for source block error
        assert.has_error(function () blk:get_rate() end)

        function TestSource:get_rate()
            return 5
        end

        -- Test valid get_rate()
        assert.is.equal(5, blk:get_rate())

        -- A few more blocks

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        local TestRateTripler = block.factory("TestRateTripler")
        function TestRateTripler:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end
        function TestRateTripler:get_rate()
            return block.Block.get_rate(self)*3
        end

        local TestRateHalver = block.factory("TestRateHalver")
        function TestRateHalver:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end
        function TestRateHalver:get_rate()
            return block.Block.get_rate(self)/2
        end

        -- Mock pipe class

        local MockPipe = class.factory()

        function MockPipe.new(src, dst)
            return setmetatable({src = src, dst = dst}, MockPipe)
        end

        function MockPipe:get_rate()
            return self.src:get_rate()
        end

        -- Build pipeline
        --  TestSource -> TestRateTripler -> TestBlock -> TestRateHalver -> TestBlock

        -- Instantiate blocks
        local b0 = TestSource()
        local b1 = TestRateTripler()
        local b2 = TestBlock()
        local b3 = TestRateHalver()
        local b4 = TestBlock()

        -- Differentiate blocks
        b0:differentiate({})
        b1:differentiate({radio.types.Float32})
        b2:differentiate({radio.types.Float32})
        b3:differentiate({radio.types.Float32})
        b4:differentiate({radio.types.Float32})

        -- Connect pipes
        for _, blks in ipairs({{b0, b1}, {b1, b2}, {b2, b3}, {b3, b4}}) do
            local src, dst = unpack(blks)
            local p = MockPipe(src, dst)
            src.outputs[1].pipes = {p}
            dst.inputs[1].pipe = p
        end

        -- Check rates
        assert.is.equal(5, b0:get_rate())
        assert.is.equal(15, b1:get_rate())
        assert.is.equal(15, b2:get_rate())
        assert.is.equal(7.5, b3:get_rate())
        assert.is.equal(7.5, b4:get_rate())
    end)

    it("basic usage", function ()
        local TestBlock = block.factory('TestBlock')

        function TestBlock:instantiate(a)
            self.a = a
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        function TestBlock:initialize()
            self.state = 123
        end

        function TestBlock:process(x)
            return 2*x
        end

        -- Instantiate TestBlock
        local blk = TestBlock(5)

        -- Differentiate block
        blk:differentiate({radio.types.Float32})

        -- Initialize block
        blk:initialize()

        -- Process
        local out = blk:process(10)

        assert.is.equal(5, blk.a)
        assert.is.equal(123, blk.state)
        assert.is.equal(20, out)
    end)

    it("inheritance", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate(a)
            self.a = a
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        function TestBlock:process(x)
            return self.a*x
        end

        -- Create a derived TestBlock

        local TestDerivedBlock = block.factory("TestDerivedBlock", TestBlock)

        function TestDerivedBlock:instantiate()
            TestBlock.instantiate(self, 5)
        end

        -- Instantiate TestBlock
        local blk = TestDerivedBlock()

        -- Differentiate block
        blk:differentiate({radio.types.Float32})

        -- Initialize block
        blk:initialize()

        -- Process
        local out = blk:process(2)

        assert.is.equal(5, blk.a)
        assert.is.equal(TestBlock.process, blk.process)
        assert.is.equal(TestBlock.initialize, blk.initialize)
        assert.is.equal(10, out)
    end)

    it("running source block", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate(vector)
            self.vector = vector
            self.vector_index = 0

            self:add_type_signature({}, {block.Output("out", radio.types.Float32)})
        end

        function TestSource:process()
            if self.vector_index == self.vector.length then
                return nil
            end

            local out = radio.types.Float32.vector_from_array({self.vector.data[self.vector_index]})

            self.vector_index = self.vector_index + 1

            return out
        end

        -- Instantiate TestSource with expected vector
        local expected_vec = radio.types.Float32.vector_from_array({42, 22, 10, 123, 15})
        local blk = TestSource(expected_vec)

        -- Differentiate the block
        blk:differentiate({})

        -- Build pipes
        blk.outputs[1].pipes[1] = pipe.Pipe(blk.outputs[1], {data_type = radio.types.Float32})
        blk.outputs[1].pipes[2] = pipe.Pipe(blk.outputs[1], {data_type = radio.types.Float32})

        -- Initialize pipes
        blk.outputs[1].pipes[1]:initialize()
        blk.outputs[1].pipes[2]:initialize()

        -- Initialize block
        blk:initialize()

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        -- Check output pipe 1
        local actual_vec = blk.outputs[1].pipes[1]:read()
        assert.is.equal(expected_vec, actual_vec)

        -- Check output pipe 2
        local actual_vec = blk.outputs[1].pipes[2]:read()
        assert.is.equal(expected_vec, actual_vec)
    end)

    it("running single input block", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        function TestBlock:process(x)
            local out = radio.types.Float32.vector(x.length)

            for i = 0, x.length-1 do
                out.data[i] = radio.types.Float32(x.data[i].value*2)
            end

            return out
        end

        -- Instantiate TestBlock
        local blk = TestBlock()

        -- Differentiate block
        blk:differentiate({radio.types.Float32})

        -- Build pipes
        blk.inputs[1].pipe = pipe.Pipe({data_type = radio.types.Float32}, blk.inputs[1])
        blk.outputs[1].pipes[1] = pipe.Pipe(blk.outputs[1], {data_type = radio.types.Float32})
        blk.outputs[1].pipes[2] = pipe.Pipe(blk.outputs[1], {data_type = radio.types.Float32})

        -- Initialize pipes
        blk.inputs[1].pipe:initialize()
        blk.outputs[1].pipes[1]:initialize()
        blk.outputs[1].pipes[2]:initialize()

        -- Initialize block
        blk:initialize()

        -- Load the input pipe and close output
        blk.inputs[1].pipe:write(radio.types.Float32.vector_from_array({1, 2, 3, 4, 5}))
        blk.inputs[1].pipe:close_output()

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        local expected_vec = radio.types.Float32.vector_from_array({2, 4, 6, 8, 10})

        -- Check the output pipe 1
        assert.is.equal(expected_vec, blk.outputs[1].pipes[1]:read())

        -- Check the output pipe 1
        assert.is.equal(expected_vec, blk.outputs[1].pipes[2]:read())
    end)

    it("running multiple input block", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.Float32), block.Input("in2", radio.types.Float32)}, {block.Output("out1", radio.types.Float32), block.Output("out2", radio.types.Float32)})
        end

        function TestBlock:process(x, y)
            local out_sum = radio.types.Float32.vector(x.length)
            local out_mul = radio.types.Float32.vector(x.length)

            for i = 0, x.length-1  do
                out_sum.data[i] = x.data[i] + y.data[i]
                out_mul.data[i] = x.data[i] * y.data[i]
            end

            return out_sum, out_mul
        end

        -- Instantiate TestBlock
        local blk = TestBlock()

        -- Differentiate block
        blk:differentiate({radio.types.Float32, radio.types.Float32})

        -- Build pipes
        blk.inputs[1].pipe = pipe.Pipe({data_type = radio.types.Float32}, blk.inputs[1])
        blk.inputs[2].pipe = pipe.Pipe({data_type = radio.types.Float32}, blk.inputs[2])
        blk.outputs[1].pipes[1] = pipe.Pipe(blk.outputs[1], {data_type = radio.types.Float32})
        blk.outputs[2].pipes[1] = pipe.Pipe(blk.outputs[2], {data_type = radio.types.Float32})

        -- Initialize pipes
        blk.inputs[1].pipe:initialize()
        blk.inputs[2].pipe:initialize()
        blk.outputs[1].pipes[1]:initialize()
        blk.outputs[2].pipes[1]:initialize()

        -- Initialize block
        blk:initialize()

        -- Load input pipe 1 and close output
        local vec = radio.types.Float32.vector(1024)
        for i = 0, vec.length-1 do
            vec.data[i].value = i
        end
        blk.inputs[1].pipe:write(vec)
        blk.inputs[1].pipe:close_output()

        -- Load input pipe 2 and close output
        local vec = radio.types.Float32.vector(956)
        for i = 0, vec.length-1 do
            vec.data[i].value = i
        end
        blk.inputs[2].pipe:write(vec)
        blk.inputs[2].pipe:close_output()

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        -- Check output 1 pipe
        local expected_vec = radio.types.Float32.vector(956)
        for i = 0, expected_vec.length-1 do
            expected_vec.data[i].value = i + i
        end
        local actual_vec = blk.outputs[1].pipes[1]:read()
        assert.is.equal(expected_vec, actual_vec)

        -- Check output 2 pipe
        local expected_vec = radio.types.Float32.vector(956)
        for i = 0, expected_vec.length-1 do
            expected_vec.data[i].value = i * i
        end
        local actual_vec = blk.outputs[2].pipes[1]:read()
        assert.is.equal(expected_vec, actual_vec)
    end)
end)
