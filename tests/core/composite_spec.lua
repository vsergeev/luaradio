local radio = require('radio')
local util = require('radio.core.util')
local class = require('radio.core.class')
local block = require('radio.core.block')
local composite = require('radio.core.composite')

describe("composite", function ()
    it("connection logic", function ()
        local TestSource = block.factory("TestSource")
        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSplitBlock = block.factory("TestSplitBlock")
        function TestSplitBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.Float32), block.Output("out2", radio.types.Float32)})
        end

        local TestSink = block.factory("TestSink")
        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end


        -- Connect by name

        --[[
                      a        c        d        f
                [ 1 ] -> [ 3 ] -> [ 4 ] -> [ 6 ] -> [ 7 ]
                           ^                 ^
                         b |               e |   g        h
                         [ 2 ]             [ 5 ] -> [ 8 ] -> [ 9 ]
        --]]

        local top = radio.CompositeBlock()
        local b1 = TestSource()
        local b2 = TestSource()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestSource()
        local b6 = TestAddBlock()
        local b7 = TestSink()
        local b8 = TestBlock()
        local b9 = TestSink()

        top:connect(b1, "out", b3, "in1")
        top:connect(b2, "out", b3, "in2")
        top:connect(b3, "out", b4, "in")
        top:connect(b4, "out", b6, "in1")
        top:connect(b5, "out", b6, "in2")
        top:connect(b6, "out", b7, "in")
        top:connect(b5, "out", b8, "in")
        top:connect(b8, "out", b9, "in")

        assert.are.same(top._connections[b3.inputs[1]], b1.outputs[1]) -- a
        assert.are.same(top._connections[b3.inputs[2]], b2.outputs[1]) -- b
        assert.are.same(top._connections[b4.inputs[1]], b3.outputs[1]) -- c
        assert.are.same(top._connections[b6.inputs[1]], b4.outputs[1]) -- d
        assert.are.same(top._connections[b6.inputs[2]], b5.outputs[1]) -- e
        assert.are.same(top._connections[b8.inputs[1]], b5.outputs[1]) -- g
        assert.are.same(top._connections[b7.inputs[1]], b6.outputs[1]) -- f
        assert.are.same(top._connections[b9.inputs[1]], b8.outputs[1]) -- g

        -- Linear connections and connect by name
        local top = radio.CompositeBlock()

        local b1 = TestSource()
        local b2 = TestSource()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestSource()
        local b6 = TestAddBlock()
        local b7 = TestSink()
        local b8 = TestBlock()
        local b9 = TestSink()

        top:connect(b3, b4)
        top:connect(b6, b7)
        top:connect(b5, b8, b9)
        top:connect(b1, "out", b3, "in1")
        top:connect(b2, "out", b3, "in2")
        top:connect(b4, "out", b6, "in1")
        top:connect(b5, "out", b6, "in2")

        assert.are.same(top._connections[b3.inputs[1]], b1.outputs[1]) -- a
        assert.are.same(top._connections[b3.inputs[2]], b2.outputs[1]) -- b
        assert.are.same(top._connections[b4.inputs[1]], b3.outputs[1]) -- c
        assert.are.same(top._connections[b6.inputs[1]], b4.outputs[1]) -- d
        assert.are.same(top._connections[b8.inputs[1]], b5.outputs[1]) -- e
        assert.are.same(top._connections[b6.inputs[2]], b5.outputs[1]) -- g
        assert.are.same(top._connections[b7.inputs[1]], b6.outputs[1]) -- f
        assert.are.same(top._connections[b9.inputs[1]], b8.outputs[1]) -- g

        -- Check invalid connections

        local top = radio.CompositeBlock()
        local b1 = TestSource()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestSplitBlock()
        local b5 = TestSink()
        local b6 = TestBlock()

        -- Linear connection of 2 output ports to 1 input port
        assert.has_error(function () top:connect(b4, b2) end)

        -- Linear connection of 1 output port to 2 input ports
        assert.has_error(function () top:connect(b2, b3) end)

        -- Connection of input port to output port
        assert.has_error(function () top:connect(b6, "in", b2, "out") end)

        -- Unknown source port
        assert.has_error(function () top:connect(b1, "foo", b2, "in") end)

        -- Unknown destination port
        assert.has_error(function () top:connect(b1, "out", b2, "foo") end)

        -- Duplicate input connection
        top:connect(b1, "out", b2, "in")
        assert.has_error(function () top:connect(b1, "out", b2, "in") end)
    end)

    it("input/output aliasing", function ()
        local blk = radio.CompositeBlock()

        -- Check aliased pipe properties

        blk:add_type_signature({block.Input("in1", radio.types.Float32), block.Input("in2", radio.types.Float32)}, {block.Output("out1", radio.types.Byte), block.Output("out2", radio.types.Bit)})

        assert.is.equal(1, #blk.signatures)
        assert.is.equal(2, #blk.inputs)
        assert.is_true(class.isinstanceof(blk.inputs[1], block.AliasedInputPort))
        assert.is_true(class.isinstanceof(blk.inputs[2], block.AliasedInputPort))
        assert.is.equal("in1", blk.inputs[1].name)
        assert.is.equal("in2", blk.inputs[2].name)
        assert.is.equal(2, #blk.outputs)
        assert.is_true(class.isinstanceof(blk.outputs[1], block.AliasedOutputPort))
        assert.is_true(class.isinstanceof(blk.outputs[2], block.AliasedOutputPort))
        assert.is.equal("out1", blk.outputs[1].name)
        assert.is.equal("out2", blk.outputs[2].name)

        -- Test blocks for composition

        local TestBlock1 = block.factory("TestBlock1")
        function TestBlock1:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Bit)})
        end

        local TestBlock2 = block.factory("TestBlock2")
        function TestBlock2:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {})
        end

        local TestBlock3 = block.factory("TestBlock3")
        function TestBlock3:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Byte)})
        end

        local b1 = TestBlock1()
        local b2 = TestBlock2()
        local b3 = TestBlock3()

        -- Check valid composite to block aliases

        --[[
                         blk
                    --------------
            in1 -> | --> [b1] --> | -> out1
            in2 -> | --> [b2]     |
                   | \-> [b3] --> | -> out2
                   ---------------
        --]]

        blk:connect(blk, "in1", b1, "in")
        blk:connect(blk, "in2", b2, "in")
        blk:connect(blk, "in2", b3, "in")
        blk:connect(blk, "out1", b1, "out")
        blk:connect(blk, "out2", b3, "out")

        assert.is.same(blk._connections[b1.inputs[1]], blk.inputs[1])
        assert.is.same(blk._connections[b2.inputs[1]], blk.inputs[2])
        assert.is.same(blk._connections[b3.inputs[1]], blk.inputs[2])
        assert.is.same(blk._connections[blk.outputs[1]], b1.outputs[1])
        assert.is.same(blk._connections[blk.outputs[2]], b3.outputs[1])

        -- Check valid composite to composite aliases

        --[[

                          blk2
                  ---------------------|
            in -> | --> in1 [blk] out1 | x
                  | \-> in2       out2 | -> out
                  ---------------------

        ]]--

        local blk2 = radio.CompositeBlock()

        blk2:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Byte)})

        blk2:connect(blk2, 'in', blk, 'in1')
        blk2:connect(blk2, 'in', blk, 'in2')
        blk2:connect(blk2, 'out', blk, 'out2')

        assert.is.same(blk2._connections[blk.inputs[1]], blk2.inputs[1])
        assert.is.same(blk2._connections[blk.inputs[2]], blk2.inputs[1])
        assert.is.same(blk2._connections[blk2.outputs[1]], blk.outputs[2])

        -- Check invalid composite to block aliases

        local blk = radio.CompositeBlock()

        blk:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.Float32)}, {block.Output("out", radio.types.Byte)})

        -- Invalid direction
        assert.has_error(function () blk:connect(blk, "out", b1, "in") end)
        assert.has_error(function () blk:connect(blk, "in1", b3, "out") end)

        -- Duplicate output connection
        local b3 = TestBlock3()
        local b4 = TestBlock3()
        blk:connect(blk, "out", b3, "out")
        assert.has_error(function () blk:connect(blk, "out", b4, "out") end)
        assert.has_error(function () blk:connect(b4, "out", blk, "out") end)

        -- Aliased input colliding with an input connection
        local b1 = TestBlock1()
        local b2 = TestBlock1()
        blk:connect(blk, "in1", b1, "in")
        assert.has_error(function () blk:connect(b2, "out", b1, "in") end)
    end)

    it("build dependency graph", function ()
        --[[
            -- [1] -- [2] -- [3] -- [4] -- [5] --
                              | \
                   -- [6] -- [7] \- [8] -- [9] --
        ]]--

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestBlock()
        local b6 = TestBlock()
        local b7 = TestBlock()
        local b8 = TestBlock()
        local b9 = TestBlock()

        top:connect(b1, b2)
        top:connect(b6, b7)
        top:connect(b2, "out", b3, "in1")
        top:connect(b7, "out", b3, "in2")
        top:connect(b3, b4, b5)
        top:connect(b3, b8, b9)

        -- Check dependency graph
        local dependency_graph = composite._build_dependency_graph(top._connections)

        assert.is.equal(9, util.table_length(dependency_graph))
        assert.are.same({b4}, dependency_graph[b5])
        assert.are.same({b8}, dependency_graph[b9])
        assert.are.same({b3}, dependency_graph[b4])
        assert.are.same({b3}, dependency_graph[b8])
        assert.is_true(util.array_equals({b7, b2}, dependency_graph[b3]) or util.array_equals({b2, b7}, dependency_graph[b3]))
        assert.are.same({b6}, dependency_graph[b7])
        assert.are.same({b1}, dependency_graph[b2])
        assert.are.same({}, dependency_graph[b1])
        assert.are.same({}, dependency_graph[b6])
    end)

    it("build reverse dependency graph", function ()
        --[[
            -- [1] -- [2] -- [3] -- [4] -- [5] --
                              | \
                   -- [6] -- [7] \- [8] -- [9] --
        ]]--

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestBlock()
        local b6 = TestBlock()
        local b7 = TestBlock()
        local b8 = TestBlock()
        local b9 = TestBlock()

        top:connect(b1, b2)
        top:connect(b6, b7)
        top:connect(b2, "out", b3, "in1")
        top:connect(b7, "out", b3, "in2")
        top:connect(b3, b4, b5)
        top:connect(b3, b8, b9)

        -- Check dependency graph
        local dependency_graph = composite._build_reverse_dependency_graph(top._connections)

        assert.is.equal(9, util.table_length(dependency_graph))
        assert.are.same({}, dependency_graph[b5])
        assert.are.same({}, dependency_graph[b9])
        assert.are.same({b5}, dependency_graph[b4])
        assert.are.same({b9}, dependency_graph[b8])
        assert.is_true(util.array_equals({b4, b8}, dependency_graph[b3]) or util.array_equals({b8, b4}, dependency_graph[b3]))
        assert.are.same({b3}, dependency_graph[b7])
        assert.are.same({b3}, dependency_graph[b2])
        assert.are.same({b2}, dependency_graph[b1])
        assert.are.same({b7}, dependency_graph[b6])
    end)

    it("build skip set", function ()
        --[[
            -- [1] -- [2] -- [3] -- [4] -- [5] --
                              | \
                   -- [6] -- [7] \- [8] -- [9] --
        ]]--

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestBlock()
        local b6 = TestBlock()
        local b7 = TestBlock()
        local b8 = TestBlock()
        local b9 = TestBlock()

        top:connect(b1, b2)
        top:connect(b6, b7)
        top:connect(b2, "out", b3, "in1")
        top:connect(b7, "out", b3, "in2")
        top:connect(b3, b4, b5)
        top:connect(b3, b8, b9)

        -- Check dependency graph
        local dependency_graph = composite._build_skip_set(top._connections)

        assert.is.equal(9, util.table_length(dependency_graph))
        assert.are.same({[b2] = true, [b3] = true, [b4] = true, [b5] = true, [b8] = true, [b9] = true}, dependency_graph[b1])
        assert.are.same({[b3] = true, [b4] = true, [b5] = true, [b8] = true, [b9] = true}, dependency_graph[b2])
        assert.are.same({[b4] = true, [b5] = true, [b8] = true, [b9] = true}, dependency_graph[b3])
        assert.are.same({[b5] = true}, dependency_graph[b4])
        assert.are.same({}, dependency_graph[b5])
        assert.are.same({[b7] = true, [b3] = true, [b4] = true, [b5] = true, [b8] = true, [b9] = true}, dependency_graph[b6])
        assert.are.same({[b3] = true, [b4] = true, [b5] = true, [b8] = true, [b9] = true}, dependency_graph[b7])
        assert.are.same({[b9] = true}, dependency_graph[b8])
        assert.are.same({}, dependency_graph[b9])
    end)

    it("build evaluation order", function ()
        --[[
            -- [1] -- [2] -- [3] -- [4] -- [5] --
                              | \
                   -- [6] -- [7] \- [8] -- [9] --
        ]]--


        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestBlock()
        local b5 = TestBlock()
        local b6 = TestBlock()
        local b7 = TestBlock()
        local b8 = TestBlock()
        local b9 = TestBlock()

        top:connect(b1, b2)
        top:connect(b6, b7)
        top:connect(b2, "out", b3, "in1")
        top:connect(b7, "out", b3, "in2")
        top:connect(b3, b4, b5)
        top:connect(b3, b8, b9)

        -- Check evaluation order
        local dependency_graph = composite._build_dependency_graph(top._connections)
        local evaluation_order = composite._build_evaluation_order(dependency_graph)

        assert.is_true(util.array_find(evaluation_order, b1) < util.array_find(evaluation_order, b2))
        assert.is_true(util.array_find(evaluation_order, b2) < util.array_find(evaluation_order, b3))
        assert.is_true(util.array_find(evaluation_order, b3) < util.array_find(evaluation_order, b4))
        assert.is_true(util.array_find(evaluation_order, b4) < util.array_find(evaluation_order, b5))
        assert.is_true(util.array_find(evaluation_order, b6) < util.array_find(evaluation_order, b7))
        assert.is_true(util.array_find(evaluation_order, b7) < util.array_find(evaluation_order, b3))
        assert.is_true(util.array_find(evaluation_order, b3) < util.array_find(evaluation_order, b8))
        assert.is_true(util.array_find(evaluation_order, b8) < util.array_find(evaluation_order, b9))
    end)

    it("running errors", function ()
        local TestSource = block.factory("TestSource")
        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSink = block.factory("TestSink")
        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        -- Unconnected inputs

        local top = radio.CompositeBlock()
        local b0 = TestBlock()
        local b1 = TestSink()
        top:connect(b0, b1)

        assert.has_error(function () top:_prepare_to_run() end)

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestAddBlock()
        local b2 = TestSink()
        top:connect(b0, "out", b1, "in1")
        top:connect(b1, "out", b2, "in")

        assert.has_error(function () top:_prepare_to_run() end)

        -- Input rate mismatch

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSource()
        local b2 = TestAddBlock()
        b0.get_rate = function (self) return 1 end
        b1.get_rate = function (self) return 2 end
        top:connect(b0, "out", b2, "in1")
        top:connect(b1, "out", b2, "in2")

        assert.has_error(function () top:_prepare_to_run() end)

        -- No compatible signatures

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.Float32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSource()
        local b2 = TestAddBlock()
        local b3 = TestSink()
        top:connect(b0, "out", b2, "in1")
        top:connect(b1, "out", b2, "in2")
        top:connect(b2, "out", b3, "in")

        assert.has_error(function () top:_prepare_to_run() end)

        -- Initialization error

        function TestSink:initialize()
            error('foobar')
        end

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSink()
        top:connect(b0, b1)

        assert.has_error(function () top:_prepare_to_run() end)
    end)

    it("composite validate inputs", function ()
        --[[
                      Composite1
              [0] - [ [A] - [B] ] - [1]
                             |
                            [C]
        --]]

        local TestSourceBlock = block.factory("TestSourceBlock")
        function TestSourceBlock:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSinkBlock = block.factory("TestSinkBlock")
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        local TestCompositeBlock = block.factory("TestComposite", radio.blocks.CompositeBlock)
        function TestCompositeBlock:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local b0 = TestSourceBlock()
        local c1a = TestBlock()
        local c1b = TestAddBlock()
        local c1c = TestSourceBlock()
        local b1 = TestSinkBlock()

        -- All inputs connected
        local c1 = TestCompositeBlock()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1c, 'out', c1b, 'in2')
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")
        local top = radio.CompositeBlock()
        top:connect(b0, c1, b1)

        assert.has_no.errors(function () top:_validate_inputs() end)

        -- c1 external input not connected
        local c1 = TestCompositeBlock()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1c, 'out', c1b, 'in2')
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")
        local top = radio.CompositeBlock()
        top:connect(c1, b1)

        assert.has_errors(function () top:_validate_inputs() end)

        -- c1a aliased input not connected
        local c1 = TestCompositeBlock()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1c, 'out', c1b, 'in2')
        c1:connect(c1, "out", c1b, "out")
        local top = radio.CompositeBlock()
        top:connect(b0, c1, b1)

        assert.has_errors(function () top:_validate_inputs() end)

        -- c1b internal input not connected
        local c1 = TestCompositeBlock()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")
        local top = radio.CompositeBlock()
        top:connect(b0, c1, b1)

        assert.has_errors(function () top:_validate_inputs() end)
    end)

    it("composite evaluation order", function ()
        --[[
                      Composite1
              [0] - [ [A] - [B] ] - [1]
                             |
                            [C]
        --]]

        local TestSourceBlock = block.factory("TestSourceBlock")
        function TestSourceBlock:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSinkBlock = block.factory("TestSinkBlock")
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        local TestCompositeBlock = block.factory("TestComposite", radio.blocks.CompositeBlock)
        function TestCompositeBlock:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local b0 = TestSourceBlock()
        local c1a = TestBlock()
        local c1b = TestAddBlock()
        local c1c = TestSourceBlock()
        local b1 = TestSinkBlock()

        local c1 = TestCompositeBlock()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1c, 'out', c1b, 'in2')
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")
        local top = radio.CompositeBlock()
        top:connect(b0, c1, b1)

        top:_validate_inputs()
        top:_differentiate()

        assert.is.equal(#top._evaluation_order, 3)
        assert.is.equal(top._evaluation_order[1], b0)
        assert.is.equal(top._evaluation_order[2], c1)
        assert.is.equal(top._evaluation_order[3], b1)

        assert.is.equal(#c1._evaluation_order, 3)
        assert.is_true((c1._evaluation_order[1] == c1c and c1._evaluation_order[2] == c1a) or
                       (c1._evaluation_order[1] == c1a and c1._evaluation_order[2] == c1c))
        assert.is.equal(c1._evaluation_order[3], c1b)
    end)

    it("composite differentiation", function ()
        --[[
                      Composite1      Composite2
              [0] - [ [A] - [B] ] - [ [D] - [E] ] - [1]
                             |
                            [C]
        --]]

        local TestSourceBlock = block.factory("TestSourceBlock")
        function TestSourceBlock:instantiate(src_type)
            self:add_type_signature({}, {block.Output("out", src_type)})
        end

        local TestBlock1 = block.factory("TestBlock1")
        function TestBlock1:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
        end

        local TestBlock2 = block.factory("TestBlock2")
        function TestBlock2:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
            self:add_type_signature({block.Input("in1", radio.types.Float32), block.Input("in2", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        local TestSinkBlock = block.factory("TestSinkBlock")
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {})
        end

        local TestComposite1 = block.factory("TestComposite1", radio.blocks.CompositeBlock)
        function TestComposite1:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Float32)})
        end

        local TestComposite2 = block.factory("TestComposite2", radio.blocks.CompositeBlock)
        function TestComposite2:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.Float32)}, {block.Output("out", radio.types.Float32)})
        end

        local b0 = TestSourceBlock(radio.types.ComplexFloat32)
        local c1a = TestBlock1()
        local c1b = TestAddBlock()
        local c1c = TestSourceBlock(radio.types.Float32)
        local c2d = TestBlock2()
        local c2e = TestBlock1()
        local b1 = TestSinkBlock()

        local c1 = TestComposite1()
        c1:connect(c1a, 'out', c1b, 'in1')
        c1:connect(c1c, 'out', c1b, 'in2')
        c1:connect(c1, 'in', c1a, 'in')
        c1:connect(c1, 'out', c1b, 'out')
        local c2 = TestComposite2()
        c2:connect(c2d, c2e)
        c2:connect(c2, 'in', c2d, 'in')
        c2:connect(c2, 'out', c2e, 'out')
        local top = radio.CompositeBlock()
        top:connect(b0, c1, c2, b1)

        --- Test normal operation
        top:_differentiate()

        -- Check types in top level flow graph
        assert.is.same(b0.inputs, {})
        assert.is.equal(b0.outputs[1].data_type, radio.types.ComplexFloat32)
        assert.is.equal(c1.inputs[1].data_type, radio.types.ComplexFloat32)
        assert.is.equal(c1.outputs[1].data_type, radio.types.Float32)
        assert.is.equal(c2.inputs[1].data_type, radio.types.Float32)
        assert.is.equal(c2.outputs[1].data_type, radio.types.Float32)
        assert.is.equal(b1.inputs[1].data_type, radio.types.Float32)
        assert.is.same(b1.outputs, {})

        -- Check types inside composite 1 flow graph
        assert.is.equal(c1a.inputs[1].data_type, radio.types.ComplexFloat32)
        assert.is.equal(c1a.outputs[1].data_type, radio.types.Float32)
        assert.is.equal(c1b.inputs[1].data_type, radio.types.Float32)
        assert.is.equal(c1b.inputs[2].data_type, radio.types.Float32)
        assert.is.equal(c1b.outputs[1].data_type, radio.types.Float32)
        assert.is.same(c1c.inputs, {})
        assert.is.equal(c1c.outputs[1].data_type, radio.types.Float32)

        -- Check types inside composite 2 flow graph
        assert.is.equal(c2d.inputs[1].data_type, radio.types.Float32)
        assert.is.equal(c2d.outputs[1].data_type, radio.types.ComplexFloat32)
        assert.is.equal(c2e.inputs[1].data_type, radio.types.ComplexFloat32)
        assert.is.equal(c2e.outputs[1].data_type, radio.types.Float32)

        --- Test unsupported input type with composite 1

        c1.signatures[1].inputs[1].data_type = radio.types.Bit
        assert.has_errors(function () top:_differentiate() end)
        c1.signatures[1].inputs[1].data_type = radio.types.ComplexFloat32

        --- Test unsupported input type with composite 2

        c2.signatures[1].inputs[1].data_type = radio.types.Bit
        assert.has_errors(function () top:_differentiate() end)
        c2.signatures[1].inputs[1].data_type = radio.types.Float32

        --- Test unsupported types inside composite 1

        c1c.signatures[1].outputs[1].data_type = radio.types.ComplexFloat32
        assert.has_errors(function () top:_differentiate() end)
        c1c.signatures[1].outputs[1].data_type = radio.types.Float32

        --- Test aliased input type mismatch

        b0.signatures[1].outputs[1].data_type = radio.types.Bit
        c1.signatures[1].inputs[1].data_type = radio.types.Bit
        assert.has_errors(function () top:_differentiate() end)
        b0.signatures[1].outputs[1].data_type = radio.types.ComplexFloat32
        c1.signatures[1].inputs[1].data_type = radio.types.ComplexFloat32

        --- Test aliased output type mismatch

        c1.signatures[1].outputs[1].data_type = radio.types.ComplexFloat32
        assert.has_errors(function () top:_differentiate() end)
        c1.signatures[1].outputs[1].data_type = radio.types.Float32
    end)

    it("composite crawl connections and connect pipes", function ()
        --[[
                                  Composite3
                     ___________________________________
                    [     Composite1      Composite2    ]
              [0] - [ - [-[A] - [C]-] - [-[E] - [G]-] - ] - [2]
                    [   [        |  ]   [\              ]
              [1] - [ - [-[B] - [D] ]   [ [F] - [H]-] - ] - [3]
                     -----------------------------------
        --]]

        local TestSourceBlock = block.factory("TestSourceBlock")
        function TestSourceBlock:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSinkBlock = block.factory("TestSinkBlock")
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        local TestComposite1 = block.factory("TestComposite1", radio.blocks.CompositeBlock)
        function TestComposite1:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestComposite2 = block.factory("TestComposite2", radio.blocks.CompositeBlock)
        function TestComposite2:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end

        local TestComposite3 = block.factory("TestComposite3", radio.blocks.CompositeBlock)
        function TestComposite3:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end

        local b0 = TestSourceBlock()
        local b1 = TestSourceBlock()
        local c1a = TestBlock()
        local c1b = TestBlock()
        local c1c = TestAddBlock()
        local c1d = TestBlock()
        local c2e = TestBlock()
        local c2f = TestBlock()
        local c2g = TestBlock()
        local c2h = TestBlock()
        local b2 = TestSinkBlock()
        local b3 = TestSinkBlock()

        local c1 = TestComposite1()
        c1:connect(c1a, 'out', c1c, 'in1')
        c1:connect(c1d, 'out', c1c, 'in2')
        c1:connect(c1b, c1d)
        c1:connect(c1a, 'in', c1, 'in1')
        c1:connect(c1b, 'in', c1, 'in2')
        c1:connect(c1c, 'out', c1, 'out')
        local c2 = TestComposite2()
        c2:connect(c2e, c2g)
        c2:connect(c2f, c2h)
        c2:connect(c2e, 'in', c2, 'in')
        c2:connect(c2f, 'in', c2, 'in')
        c2:connect(c2g, 'out', c2, 'out1')
        c2:connect(c2h, 'out', c2, 'out2')
        local c3 = TestComposite3()
        c3:connect(c1, c2)
        c3:connect(c1, 'in1', c3, 'in1')
        c3:connect(c1, 'in2', c3, 'in2')
        c3:connect(c2, 'out1', c3, 'out1')
        c3:connect(c2, 'out2', c3, 'out2')
        local top = radio.CompositeBlock()
        top:connect(b0, 'out', c3, 'in1')
        top:connect(b1, 'out', c3, 'in2')
        top:connect(c3, 'out1', b2, 'in')
        top:connect(c3, 'out2', b3, 'in')

        top:_validate_inputs()
        top:_differentiate()

        local all_connections = top:_crawl_connections()

        local expected_connections = {
            [c1a.inputs[1]] = b0.outputs[1],
            [c1b.inputs[1]] = b1.outputs[1],
            [c1c.inputs[1]] = c1a.outputs[1],
            [c1c.inputs[2]] = c1d.outputs[1],
            [c1d.inputs[1]] = c1b.outputs[1],
            [c2e.inputs[1]] = c1c.outputs[1],
            [c2f.inputs[1]] = c1c.outputs[1],
            [c2g.inputs[1]] = c2e.outputs[1],
            [c2h.inputs[1]] = c2f.outputs[1],
            [b2.inputs[1]] = c2g.outputs[1],
            [b3.inputs[1]] = c2h.outputs[1],
        }

        assert.is.same(expected_connections, all_connections)

        top:_connect_pipes(all_connections)

        assert.is_not_nil(c1a.inputs[1].pipe)
        assert.is.same(c1a.inputs[1].pipe, b0.outputs[1].pipes[1])

        assert.is_not_nil(c1b.inputs[1].pipe)
        assert.is.same(c1b.inputs[1].pipe, b1.outputs[1].pipes[1])

        assert.is_not_nil(c1c.inputs[1].pipe)
        assert.is.same(c1c.inputs[1].pipe, c1a.outputs[1].pipes[1])

        assert.is_not_nil(c1c.inputs[2].pipe)
        assert.is.same(c1c.inputs[2].pipe, c1d.outputs[1].pipes[1])

        assert.is_not_nil(c1d.inputs[1].pipe)
        assert.is.same(c1d.inputs[1].pipe, c1b.outputs[1].pipes[1])

        assert.is_not_nil(c2e.inputs[1].pipe)
        assert.is_not_nil(c2f.inputs[1].pipe)
        assert.is_true((c2e.inputs[1].pipe == c1c.outputs[1].pipes[1] and c2f.inputs[1].pipe == c1c.outputs[1].pipes[2]) or
                       (c2e.inputs[1].pipe == c1c.outputs[1].pipes[2] and c2f.inputs[1].pipe == c1c.outputs[1].pipes[1]))

        assert.is_not_nil(c2g.inputs[1].pipe)
        assert.is.same(c2g.inputs[1].pipe, c2e.outputs[1].pipes[1])

        assert.is_not_nil(c2h.inputs[1].pipe)
        assert.is.same(c2h.inputs[1].pipe, c2f.outputs[1].pipes[1])

        assert.is_not_nil(b2.inputs[1].pipe)
        assert.is.same(b2.inputs[1].pipe, c2g.outputs[1].pipes[1])

        assert.is_not_nil(b3.inputs[1].pipe)
        assert.is.same(b3.inputs[1].pipe, c2h.outputs[1].pipes[1])
    end)

    it("composite validate sample rates", function ()
        --[[
                                  Composite3
                     ___________________________________
                    [     Composite1      Composite2    ]
              [0] - [ - [-[A] - [C]-] - [-[E] - [G]-] - ] - [2]
                    [   [        |  ]   [\              ]
              [1] - [ - [-[B] - [D] ]   [ [F] - [H]-] - ] - [3]
                     -----------------------------------
        --]]

        local TestSourceBlock = block.factory("TestSourceBlock")
        function TestSourceBlock:instantiate(rate)
            self.rate = rate
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end
        function TestSourceBlock:get_rate()
            return self.rate
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate(rate_modifier)
            self.rate_modifier = rate_modifier or 1
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end
        function TestBlock:get_rate()
            return block.Block.get_rate(self) * self.rate_modifier
        end

        local TestAddBlock = block.factory("TestAddBlock")
        function TestAddBlock:instantiate(rate_modifier)
            self.rate_modifier = rate_modifier or 1
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end
        function TestAddBlock:get_rate()
            return block.Block.get_rate(self) * self.rate_modifier
        end

        local TestSinkBlock = block.factory("TestSinkBlock")
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        local TestComposite1 = block.factory("TestComposite1", radio.blocks.CompositeBlock)
        function TestComposite1:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestComposite2 = block.factory("TestComposite2", radio.blocks.CompositeBlock)
        function TestComposite2:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end

        local TestComposite3 = block.factory("TestComposite3", radio.blocks.CompositeBlock)
        function TestComposite3:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end

        local b0 = TestSourceBlock(1)
        local b1 = TestSourceBlock(2)
        local c1a = TestBlock()
        local c1b = TestBlock()
        local c1c = TestAddBlock(2)
        local c1d = TestBlock(0.5)
        local c2e = TestBlock()
        local c2f = TestBlock(2)
        local c2g = TestBlock()
        local c2h = TestBlock()
        local b2 = TestSinkBlock()
        local b3 = TestSinkBlock()

        local c1 = TestComposite1()
        c1:connect(c1a, 'out', c1c, 'in1')
        c1:connect(c1d, 'out', c1c, 'in2')
        c1:connect(c1b, c1d)
        c1:connect(c1a, 'in', c1, 'in1')
        c1:connect(c1b, 'in', c1, 'in2')
        c1:connect(c1c, 'out', c1, 'out')
        local c2 = TestComposite2()
        c2:connect(c2e, c2g)
        c2:connect(c2f, c2h)
        c2:connect(c2e, 'in', c2, 'in')
        c2:connect(c2f, 'in', c2, 'in')
        c2:connect(c2g, 'out', c2, 'out1')
        c2:connect(c2h, 'out', c2, 'out2')
        local c3 = TestComposite3()
        c3:connect(c1, c2)
        c3:connect(c1, 'in1', c3, 'in1')
        c3:connect(c1, 'in2', c3, 'in2')
        c3:connect(c2, 'out1', c3, 'out1')
        c3:connect(c2, 'out2', c3, 'out2')
        local top = radio.CompositeBlock()
        top:connect(b0, 'out', c3, 'in1')
        top:connect(b1, 'out', c3, 'in2')
        top:connect(c3, 'out1', b2, 'in')
        top:connect(c3, 'out2', b3, 'in')

        top:_validate_inputs()
        top:_differentiate()
        top:_connect_pipes(top:_crawl_connections())

        assert.has_no.errors(function () top:_validate_rates() end)

        assert.is.equal(b0:get_rate(), 1)
        assert.is.equal(b1:get_rate(), 2)

        assert.is.equal(c1a:get_rate(), 1)
        assert.is.equal(c1b:get_rate(), 2)
        assert.is.equal(c1c:get_rate(), 2)
        assert.is.equal(c1d:get_rate(), 1)

        assert.is.equal(c2e:get_rate(), 2)
        assert.is.equal(c2f:get_rate(), 4)
        assert.is.equal(c2g:get_rate(), 2)
        assert.is.equal(c2h:get_rate(), 4)

        assert.is.equal(b2:get_rate(), 2)
        assert.is.equal(b3:get_rate(), 4)

        c1d.rate_modifier = 1
        assert.has_errors(function () top:_validate_rates() end)
    end)

    it("composite initialization", function ()
        --[[
                                  Composite3
                     ___________________________________
                    [     Composite1      Composite2    ]
              [0] - [ - [-[A] - [C]-] - [-[E] - [G]-] - ] - [2]
                    [   [        |  ]   [\              ]
              [1] - [ - [-[B] - [D] ]   [ [F] - [H]-] - ] - [3]
                     -----------------------------------
        --]]

        local initialized = {}

        local TestBaseBlock = block.factory("TestBaseBlock")
        function TestBaseBlock:initialize()
            initialized[#initialized + 1] = self
        end

        local TestSourceBlock = block.factory("TestSourceBlock", TestBaseBlock)
        function TestSourceBlock:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.ComplexFloat32)})
        end
        function TestSourceBlock:get_rate()
            return 1
        end

        local TestBlock = block.factory("TestBlock", TestBaseBlock)
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestAddBlock = block.factory("TestAddBlock", TestBaseBlock)
        function TestAddBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local TestSinkBlock = block.factory("TestSinkBlock", TestBaseBlock)
        function TestSinkBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {})
        end

        local TestComposite1 = block.factory("TestComposite1", radio.blocks.CompositeBlock)
        function TestComposite1:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end
        function TestComposite1:initialize()
            radio.blocks.CompositeBlock.initialize(self)
            initialized[#initialized + 1] = self
        end

        local TestComposite2 = block.factory("TestComposite2", radio.blocks.CompositeBlock)
        function TestComposite2:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end
        function TestComposite2:initialize()
            radio.blocks.CompositeBlock.initialize(self)
            initialized[#initialized + 1] = self
        end

        local TestComposite3 = block.factory("TestComposite3", radio.blocks.CompositeBlock)
        function TestComposite3:instantiate()
            radio.blocks.CompositeBlock.instantiate(self)

            self:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.ComplexFloat32)}, {block.Output("out1", radio.types.ComplexFloat32), block.Output("out2", radio.types.ComplexFloat32)})
        end
        function TestComposite3:initialize()
            radio.blocks.CompositeBlock.initialize(self)
            initialized[#initialized + 1] = self
        end

        local b0 = TestSourceBlock()
        local b1 = TestSourceBlock()
        local c1a = TestBlock()
        local c1b = TestBlock()
        local c1c = TestAddBlock()
        local c1d = TestBlock()
        local c2e = TestBlock()
        local c2f = TestBlock()
        local c2g = TestBlock()
        local c2h = TestBlock()
        local b2 = TestSinkBlock()
        local b3 = TestSinkBlock()

        local c1 = TestComposite1()
        c1:connect(c1a, 'out', c1c, 'in1')
        c1:connect(c1d, 'out', c1c, 'in2')
        c1:connect(c1b, c1d)
        c1:connect(c1a, 'in', c1, 'in1')
        c1:connect(c1b, 'in', c1, 'in2')
        c1:connect(c1c, 'out', c1, 'out')
        local c2 = TestComposite2()
        c2:connect(c2e, c2g)
        c2:connect(c2f, c2h)
        c2:connect(c2e, 'in', c2, 'in')
        c2:connect(c2f, 'in', c2, 'in')
        c2:connect(c2g, 'out', c2, 'out1')
        c2:connect(c2h, 'out', c2, 'out2')
        local c3 = TestComposite3()
        c3:connect(c1, c2)
        c3:connect(c1, 'in1', c3, 'in1')
        c3:connect(c1, 'in2', c3, 'in2')
        c3:connect(c2, 'out1', c3, 'out1')
        c3:connect(c2, 'out2', c3, 'out2')
        local top = radio.CompositeBlock()
        top:connect(b0, 'out', c3, 'in1')
        top:connect(b1, 'out', c3, 'in2')
        top:connect(c3, 'out1', b2, 'in')
        top:connect(c3, 'out2', b3, 'in')

        top:_validate_inputs()
        top:_differentiate()
        top:_connect_pipes(top:_crawl_connections())
        top:_validate_rates()
        top:_initialize()

        assert.is.equal(#initialized, 15)
        assert.is_true((initialized[1] == b0 and initialized[2] == b1) or
                       (initialized[1] == b1 and initialized[2] == b0))
        assert.is_true((initialized[3] == c1a and initialized[4] == c1b and initialized[5] == c1d) or
                       (initialized[3] == c1b and initialized[4] == c1d and initialized[5] == c1a) or
                       (initialized[3] == c1b and initialized[4] == c1a and initialized[5] == c1d))
        assert.is.equal(initialized[6], c1c)
        assert.is.equal(initialized[7], c1)
        assert.is_true((initialized[8] == c2e and initialized[9] == c2g and initialized[10] == c2f and initialized[11] == c2h) or
                       (initialized[8] == c2e and initialized[9] == c2f and initialized[10] == c2g and initialized[11] == c2h) or
                       (initialized[8] == c2e and initialized[9] == c2f and initialized[10] == c2h and initialized[11] == c2g) or
                       (initialized[8] == c2f and initialized[9] == c2h and initialized[10] == c2e and initialized[11] == c2g) or
                       (initialized[8] == c2f and initialized[9] == c2e and initialized[10] == c2h and initialized[11] == c2g) or
                       (initialized[8] == c2f and initialized[9] == c2e and initialized[10] == c2g and initialized[11] == c2h))
        assert.is_equal(initialized[12], c2)
        assert.is_equal(initialized[13], c3)
        assert.is_true((initialized[14] == b2 and initialized[15] == b3) or
                       (initialized[14] == b3 and initialized[15] == b2))
    end)
end)
