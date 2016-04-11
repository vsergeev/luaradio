local radio = require('radio')
local object = require('radio.core.object')
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
        assert.is_true(#blk.inputs == 0)
        assert.is_true(#blk.outputs == 0)
    end)

    it("type signatures", function ()
        local TestBlock = block.factory("TestBlock")

        -- Basic type signature
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.Float32Type)})
            self:add_type_signature({block.Input("in1", radio.Float32Type), block.Input("in2", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end

        local blk = TestBlock()
        assert.is.equal(2, #blk.signatures)
        assert.is.equal(2, #blk.inputs)
        assert.is.equal(1, #blk.outputs)
        assert.is_true(object.isinstanceof(blk.inputs[1], pipe.PipeInput))
        assert.is_true(object.isinstanceof(blk.inputs[2], pipe.PipeInput))
        assert.is_true(object.isinstanceof(blk.outputs[1], pipe.PipeOutput))

        -- Test invalid input descriptor
        function TestBlock:instantiate()
            self:add_type_signature({block.Output("in", radio.Float32Type)}, {})
        end
        assert.has_error(function () TestBlock() end)

        -- Test invalid output descriptor
        function TestBlock:instantiate()
            self:add_type_signature({}, {block.Input("out", radio.Float32Type)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched number of inputs error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.Float32Type)})
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.Float32Type)})
        end
        assert.has_error(function () TestBlock() end)

        -- Test mismatched number of outputs error
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.Float32Type)})
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out1", radio.Float32Type), block.Output("out2", radio.Float32Type)})
        end
        assert.has_error(function () TestBlock() end)
    end)

    it("type differentiation", function ()
        local TestBlock = block.factory("TestBlock")

        -- Test differentiation
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.Float32Type)},
                                    {block.Output("out", radio.Float32Type)})
            self:add_type_signature({block.Input("in1", radio.Float32Type), block.Input("in2", radio.Integer32Type)},
                                    {block.Output("out", radio.Integer32Type)})
            self:add_type_signature({block.Input("in1", radio.Integer32Type), block.Input("in2", radio.ByteType)},
                                    {block.Output("out", radio.ByteType)})
            self:add_type_signature({block.Input("in1", radio.BitType), block.Input("in2", radio.BitType)},
                                    {block.Output("out", radio.BitType)})
        end

        local blk = TestBlock()

        -- Test getting input/output types before differentiation
        assert.has_error(function () blk:get_input_types() end)
        assert.has_error(function () blk:get_output_types() end)

        -- Test valid differentiations
        blk:differentiate({radio.ComplexFloat32Type, radio.Float32Type})
        assert.is.equal(blk.signatures[1], blk.signature)
        assert.is.same({radio.ComplexFloat32Type, radio.Float32Type}, blk:get_input_types())
        assert.is.same({radio.Float32Type}, blk:get_output_types())

        blk:differentiate({radio.Float32Type, radio.Integer32Type})
        assert.is.equal(blk.signatures[2], blk.signature)
        assert.is.same({radio.Float32Type, radio.Integer32Type}, blk:get_input_types())
        assert.is.same({radio.Integer32Type}, blk:get_output_types())

        blk:differentiate({radio.Integer32Type, radio.ByteType})
        assert.is.equal(blk.signatures[3], blk.signature)
        assert.is.same({radio.Integer32Type, radio.ByteType}, blk:get_input_types())
        assert.is.same({radio.ByteType}, blk:get_output_types())

        blk:differentiate({radio.BitType, radio.BitType})
        assert.is.equal(blk.signatures[4], blk.signature)
        assert.is.same({radio.BitType, radio.BitType}, blk:get_input_types())
        assert.is.same({radio.BitType}, blk:get_output_types())

        -- Test invalid differentiations
        assert.has_error(function () blk:differentiate({}) end)
        assert.has_error(function () blk:differentiate({radio.ComplexFloat32Type}) end)
        assert.has_error(function () blk:differentiate({radio.Float32Type}) end)
        assert.has_error(function () blk:differentiate({radio.Integer32Type}) end)
        assert.has_error(function () blk:differentiate({radio.BitType}) end)
        assert.has_error(function () blk:differentiate({radio.ComplexFloat32Type, radio.ComplexFloat32Type}) end)
        assert.has_error(function () blk:differentiate({radio.Float32Type, radio.BitType}) end)
        assert.has_error(function () blk:differentiate({radio.Integer32Type, radio.BitType}) end)
        assert.has_error(function () blk:differentiate({radio.BitType, radio.ByteType}) end)

        -- Test custom type signature dependent initialize and process functions

        function TestBlock:initialize_float() end
        function TestBlock:initialize_integer() end
        function TestBlock:process_float() end
        function TestBlock:process_integer() end
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {}, TestBlock.process_float, TestBlock.initialize_float)
            self:add_type_signature({block.Input("in", radio.Integer32Type)}, {}, TestBlock.process_integer, TestBlock.initialize_integer)
            self:add_type_signature({block.Input("in", radio.BitType)}, {})
        end

        local blk = TestBlock()

        blk:differentiate({radio.Float32Type})
        assert.is.equal(TestBlock.initialize_float, blk.initialize)
        assert.is.equal(TestBlock.process_float, blk.process)
        assert.is.same({radio.Float32Type}, blk:get_input_types())
        assert.is.same({}, blk:get_output_types())

        blk:differentiate({radio.Integer32Type})
        assert.is.equal(TestBlock.initialize_integer, blk.initialize)
        assert.is.equal(TestBlock.process_integer, blk.process)
        assert.is.same({radio.Integer32Type}, blk:get_input_types())
        assert.is.same({}, blk:get_output_types())

        blk:differentiate({radio.BitType})
        assert.is.equal(TestBlock.initialize, blk.initialize)
        assert.is.equal(TestBlock.process, blk.process)
        assert.is.same({radio.BitType}, blk:get_input_types())
        assert.is.same({}, blk:get_output_types())

        -- Test source differentiation

        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.Float32Type)})
        end

        local blk = TestSource()
        blk:differentiate({})
        assert.is.equal(blk.signatures[1], blk.signature)
        assert.is.same({}, blk:get_input_types())
        assert.is.same({radio.Float32Type}, blk:get_output_types())

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
    end)

    it("rate propagation", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.Float32Type)})
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

        assert.is.equal(5, blk:get_rate())

        -- A few more blocks

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end

        local TestRateTripler = block.factory("TestRateTripler")
        function TestRateTripler:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end
        function TestRateTripler:get_rate()
            return block.Block.get_rate(self)*3
        end

        local TestRateHalver = block.factory("TestRateHalver")
        function TestRateHalver:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end
        function TestRateHalver:get_rate()
            return block.Block.get_rate(self)/2
        end

        -- Mock pipe class

        local MockPipe = object.class_factory()

        function MockPipe.new(src, dst)
            return setmetatable({src = src, dst = dst}, MockPipe)
        end

        function MockPipe:get_rate()
            return self.src:get_rate()
        end

        -- Build pipeline
        --  TestSource -> TestRateTripler -> TestBlock -> TestRateHalver -> TestBlock

        -- Create blocks
        local b0 = TestSource()
        local b1 = TestRateTripler()
        local b2 = TestBlock()
        local b3 = TestRateHalver()
        local b4 = TestBlock()

        -- Differentiate blocks
        b0:differentiate({})
        b1:differentiate({radio.Float32Type})
        b2:differentiate({radio.Float32Type})
        b3:differentiate({radio.Float32Type})
        b4:differentiate({radio.Float32Type})

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

        -- Implement some basic methods
        function TestBlock:instantiate(a)
            self.a = a
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end

        function TestBlock:initialize()
            self.state = 123
        end

        function TestBlock:process(x)
            return 2*x
        end

        -- Use the block
        local blk = TestBlock(5)
        blk:differentiate({radio.Float32Type})
        blk:initialize()
        local out = blk:process(10)

        assert.is.equal(5, blk.a)
        assert.is.equal(123, blk.state)
        assert.is.equal(20, out)
    end)

    it("inheritance", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate(a)
            self.a = a
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end

        function TestBlock:process(x)
            return self.a*x
        end

        -- Create a derived TestBlock

        local TestDerivedBlock = block.factory("TestDerivedBlock", TestBlock)

        function TestDerivedBlock:instantiate()
            TestBlock.instantiate(self, 5)
        end

        local blk = TestDerivedBlock()
        blk:differentiate({radio.Float32Type})
        blk:initialize()
        local out = blk:process(2)

        assert.is.equal(5, blk.a)
        assert.is.equal(TestBlock.process, blk.process)
        assert.is.equal(TestBlock.initialize, blk.initialize)
        assert.is.equal(10, out)
    end)

    it("running source block", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate(vec)
            self.vec = vec
            self.index = 0

            self:add_type_signature({}, {block.Output("out", radio.Float32Type)})
        end

        function TestSource:process()
            if self.index == self.vec.length then
                return nil
            end

            local out = radio.Float32Type.vector_from_array({self.vec.data[self.index]})
            self.index = self.index + 1

            return out
        end

        -- Mock pipe for writing

        local MockPipe = object.class_factory()

        function MockPipe.new()
            local self = setmetatable({}, MockPipe)
            self.vec = radio.Float32Type.vector()
            return self
        end

        function MockPipe:write(x)
            for i = 0, x.length-1 do
                self.vec:append(x.data[i])
            end
        end

        -- Create a TestSource with two output pipes
        local expected_vec = radio.Float32Type.vector_from_array({42, 22, 10, 123, 15})
        local blk = TestSource(expected_vec)
        local p1, p2 = MockPipe(), MockPipe()
        blk:differentiate({})
        blk.outputs[1].pipes = {p1, p2}
        blk:initialize()

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        -- Check contents of output pipes
        assert.is.equal(expected_vec, p1.vec)
        assert.is.equal(expected_vec, p2.vec)
    end)

    it("running single input block", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {block.Output("out", radio.Float32Type)})
        end

        function TestBlock:process(x)
            local out = radio.Float32Type.vector(x.length)

            for i = 0, x.length-1 do
                out.data[i] = radio.Float32Type(x.data[i].value*2)
            end

            return out
        end

        -- Mock pipe with read and write capabilities

        local MockPipe = object.class_factory()

        function MockPipe.new()
            local self = setmetatable({}, MockPipe)
            self.vec = radio.Float32Type.vector()
            return self
        end

        function MockPipe:write(x)
            for i = 0, x.length-1 do
                self.vec:append(x.data[i])
            end
        end

        function MockPipe:read_max()
            if self.vec.length == 0 then
                return nil
            end

            local out = self.vec
            self.vec = radio.Float32Type.vector()
            return out
        end

        function MockPipe:read_n(n)
            error("not implemented")
        end

        function MockPipe:read_update()
            error("not implemented")
        end

        -- Create a TestBlock with an input pipe and 2 output pipes
        local blk = TestBlock()
        local p_in, p_out1, p_out2 = MockPipe(), MockPipe(), MockPipe()
        blk:differentiate({radio.Float32Type})
        blk.inputs[1].pipe = p_in
        blk.outputs[1].pipes = {p_out1, p_out2}
        blk:initialize()

        -- Load the input pipe
        p_in.vec = radio.Float32Type.vector_from_array({1, 2, 3, 4, 5})

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        -- Check the output pipe
        local expected_vec = radio.Float32Type.vector_from_array({2, 4, 6, 8, 10})
        assert.is.equal(expected_vec, p_out1.vec)
        assert.is.equal(expected_vec, p_out2.vec)
    end)

    it("running multiple input block", function ()
        local TestBlock = block.factory("TestBlock")

        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.Float32Type), block.Input("in2", radio.Float32Type)}, {block.Output("out1", radio.Float32Type), block.Output("out2", radio.Float32Type)})
        end

        function TestBlock:process(x, y)
            local out_sum = radio.Float32Type.vector(x.length)
            local out_mul = radio.Float32Type.vector(x.length)

            for i = 0, x.length-1  do
                out_sum.data[i] = x.data[i] + y.data[i]
                out_mul.data[i] = x.data[i] * y.data[i]
            end

            return out_sum, out_mul
        end

        -- Mock pipe with read and write capabilities

        local MockPipe = object.class_factory()

        function MockPipe.new(n_read)
            local self = setmetatable({}, MockPipe)
            self.vec = radio.Float32Type.vector()
            self.n_read = n_read
            return self
        end

        function MockPipe:write(x)
            for i = 0, x.length-1 do
                self.vec:append(x.data[i])
            end
        end

        function MockPipe:read_max()
            return self:read_n(self:read_update())
        end

        function MockPipe:read_update()
            if self.vec.length == 0 then
                return nil
            end
            return math.min(self.vec.length, self.n_read)
        end

        function MockPipe:read_n(n)
            local out = radio.Float32Type.vector(n)

            -- Copy elements to out
            for i = 0, n-1 do
                out.data[i] = self.vec.data[i]
            end

            -- Shift down our vector
            for i = n, self.vec.length - 1 do
                self.vec.data[i-n] = self.vec.data[i]
            end

            self.vec:resize(self.vec.length - n)

            return out
        end

        -- Create a test block with 2 input pipes and 2 output pipes
        --  Pipe input 1 will read up to 3 at a time,
        --  pipe input 2 will read up to 7 at a time.
        local blk = TestBlock()
        local p_in1, p_in2, p_out1, p_out2 = MockPipe(3), MockPipe(7)
        local p_out1, p_out2 = MockPipe(), MockPipe()
        blk:differentiate({radio.Float32Type, radio.Float32Type})
        blk.inputs[1].pipe = p_in1
        blk.inputs[2].pipe = p_in2
        blk.outputs[1].pipes = {p_out1}
        blk.outputs[2].pipes = {p_out2}
        blk:initialize()

        -- Load the input pipes
        for i = 1, 1024 do
            p_in1.vec:append(radio.Float32Type(i))
        end
        for i = 1, 956 do
            p_in2.vec:append(radio.Float32Type(i))
        end

        -- Hook spy onto block cleanup()
        local cleanup_spy = spy.on(blk, "cleanup")

        -- Run the block
        blk:run()

        -- Check cleanup() was called
        assert.spy(cleanup_spy).was.called()

        -- Check output pipes
        local expected_vec1 = radio.Float32Type.vector()
        local expected_vec2 = radio.Float32Type.vector()
        for i = 1, 956 do
            expected_vec1:append(radio.Float32Type(i + i))
        end
        for i = 1, 956 do
            expected_vec2:append(radio.Float32Type(i * i))
        end
        assert.is.equal(956, p_out1.vec.length)
        assert.is.equal(956, p_out2.vec.length)
        assert.is.equal(expected_vec1, p_out1.vec)
        assert.is.equal(expected_vec2, p_out2.vec)
    end)
end)
