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

        assert.are.same({b3.inputs[1].pipe}, b1.outputs[1].pipes) -- a
        assert.are.same({b3.inputs[2].pipe}, b2.outputs[1].pipes) -- b
        assert.are.same({b4.inputs[1].pipe}, b3.outputs[1].pipes) -- c
        assert.are.same({b6.inputs[1].pipe}, b4.outputs[1].pipes) -- d
        assert.are.same({b6.inputs[2].pipe, b8.inputs[1].pipe}, b5.outputs[1].pipes) -- e and g
        assert.are.same({b7.inputs[1].pipe}, b6.outputs[1].pipes) -- f
        assert.are.same({b9.inputs[1].pipe}, b8.outputs[1].pipes) -- g

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

        assert.are.same({b3.inputs[1].pipe}, b1.outputs[1].pipes) -- a
        assert.are.same({b3.inputs[2].pipe}, b2.outputs[1].pipes) -- b
        assert.are.same({b4.inputs[1].pipe}, b3.outputs[1].pipes) -- c
        assert.are.same({b6.inputs[1].pipe}, b4.outputs[1].pipes) -- d
        assert.are.same({b8.inputs[1].pipe, b6.inputs[2].pipe}, b5.outputs[1].pipes) -- e and g
        assert.are.same({b7.inputs[1].pipe}, b6.outputs[1].pipes) -- f
        assert.are.same({b9.inputs[1].pipe}, b8.outputs[1].pipes) -- g

        -- Check invalid connections

        local top = radio.CompositeBlock()
        local b1 = TestSource()
        local b2 = TestBlock()
        local b3 = TestAddBlock()
        local b4 = TestSplitBlock()
        local b5 = TestSink()

        -- Linear connection of 2 output ports to 1 input port
        assert.has_error(function () top:connect(b4, b2) end)

        -- Linear connection of 1 output port to 2 input ports
        assert.has_error(function () top:connect(b2, b3) end)

        -- Unknown source pipe
        assert.has_error(function () top:connect(b1, "foo", b2, "in") end)

        -- Unknown destination pipe
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

        assert.is.equal(1, #blk.inputs[1].real_inputs)
        assert.is.equal(2, #blk.inputs[2].real_inputs)
        assert.is.equal(b1.inputs[1], blk.inputs[1].real_inputs[1])
        assert.is.equal(b2.inputs[1], blk.inputs[2].real_inputs[1])
        assert.is.equal(b3.inputs[1], blk.inputs[2].real_inputs[2])
        assert.is.equal(b1.outputs[1], blk.outputs[1].real_output)
        assert.is.equal(b3.outputs[1], blk.outputs[2].real_output)

        -- Check valid composite to composite aliases

        --[[

                          blk2
                  ---------------------|
            in -> | --> in1 [blk] out2 | -> out
                  | \-> in2            |
                  ---------------------

        ]]--

        local blk2 = radio.CompositeBlock()

        blk2:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.Byte)})

        blk2:connect(blk2, 'in', blk, 'in1')
        blk2:connect(blk2, 'in', blk, 'in2')
        blk2:connect(blk2, 'out', blk, 'out2')

        assert.is.equal(3, #blk2.inputs[1].real_inputs)
        assert.is.equal(b1.inputs[1], blk2.inputs[1].real_inputs[1])
        assert.is.equal(b2.inputs[1], blk2.inputs[1].real_inputs[2])
        assert.is.equal(b3.inputs[1], blk2.inputs[1].real_inputs[3])
        assert.is.equal(b3.outputs[1], blk2.outputs[1].real_output)

        -- Check invalid composite to block aliases

        local blk = radio.CompositeBlock()

        blk:add_type_signature({block.Input("in1", radio.types.ComplexFloat32), block.Input("in2", radio.types.Float32)}, {block.Output("out", radio.types.Byte)})

        -- Invalid pipe direction
        assert.has_error(function () blk:connect(blk, "out", b1, "in") end)
        assert.has_error(function () blk:connect(blk, "in", b3, "out") end)

        -- Duplicate output connection
        local b4 = TestBlock3()
        blk:connect(blk, "out", b3, "out")
        assert.has_error(function () blk:connect(blk, "out", b4, "out") end)
        assert.has_error(function () blk:connect(b4, "out", blk, "out") end)
    end)

    it("crawl connections", function ()
        --[[

                                Composite3
                         Composite1      Composite2
              [0] - [  [ [A] - [B] ] - [ [A] - [B] ] - [1]
                                |
                               [C]

        --]]

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        end

        local c1 = radio.CompositeBlock()
        local c1a = TestBlock()
        local c1b = TestBlock()
        local c1c = TestBlock()
        c1:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        c1:connect(c1a, c1b, c1c)
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")

        local c2 = radio.CompositeBlock()
        local c2a = TestBlock()
        local c2b = TestBlock()
        c2:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        c2:connect(c2a, c2b)
        c2:connect(c2, "in", c2a, "in")
        c2:connect(c2, "out", c2b, "out")

        local c3 = radio.CompositeBlock()
        c3:add_type_signature({block.Input("in", radio.types.ComplexFloat32)}, {block.Output("out", radio.types.ComplexFloat32)})
        c3:connect(c1, c2)
        c3:connect(c3, "in", c1, "in")
        c3:connect(c3, "out", c2, "out")

        local top = radio.CompositeBlock()
        local b0 = TestBlock()
        local b1 = TestBlock()
        top:connect(b0, c3, b1)

        -- Check top's uncrawled connections

        local expected_connections = {
            [c1a.inputs[1]] = b0.outputs[1],
            [b1.inputs[1]] = c2b.outputs[1]
        }
        assert.is.equal(2, util.table_length(top._connections))
        assert.is.same(expected_connections, top._connections)

        -- Check top's crawled connections

        local expected_blocks = {
            [b0] = true, [c1a] = true, [c1b] = true,
            [c1c] = true, [c2a] = true, [c2b] = true,
            [b1] = true
        }

        local expected_connections = {
            [c1a.inputs[1]] = b0.outputs[1], [c1b.inputs[1]] = c1a.outputs[1],
            [c1c.inputs[1]] = c1b.outputs[1], [c2a.inputs[1]] = c1b.outputs[1],
            [c2b.inputs[1]] = c2a.outputs[1], [b1.inputs[1]] = c2b.outputs[1]
        }

        local blocks, connections = composite._crawl_connections(top._connections)

        assert.is.equal(7, util.table_length(blocks))
        assert.is.equal(6, util.table_length(connections))
        assert.is.same(expected_blocks, blocks)
        assert.is.same(expected_connections, connections)
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

    it("build revese dependency graph", function ()
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
end)
