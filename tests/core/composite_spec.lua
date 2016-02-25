local radio = require('radio')

local util = require('radio.core.util')
local object = require('radio.core.object')
local block = require('radio.core.block')
local composite = require('radio.core.composite')
local pipe = require('radio.core.pipe')

describe("composite", function ()
    it("connection logic", function ()
        local TestSource = block.factory("TestSource")
        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSink = block.factory("TestSink")
        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {})
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
        local b3 = TestSumBlock()
        local b4 = TestBlock()
        local b5 = TestSource()
        local b6 = TestSumBlock()
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
        local b3 = TestSumBlock()
        local b4 = TestBlock()
        local b5 = TestSource()
        local b6 = TestSumBlock()
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

        -- Unknown source pipe
        assert.has.errors(function () top:connect(b1, "foo", b2, "in") end)

        -- Unknown destination pipe
        assert.has.errors(function () top:connect(b1, "out", b2, "foo") end)

        -- Duplicate input connection
        top:connect(b1, "out", b2, "in")
        assert.has.errors(function () top:connect(b1, "out", b2, "in") end)
    end)

    it("input/output aliasing", function ()
        local blk = radio.CompositeBlock()

        -- Check aliased pipe inputs / outputs

        blk:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.Float32Type)}, {block.Output("out", radio.Integer32Type)})

        assert.is.equal(1, #blk.signatures)
        assert.is.equal(2, #blk.inputs)
        assert.is_true(object.isinstanceof(blk.inputs[1], pipe.AliasedPipeInput))
        assert.is_true(object.isinstanceof(blk.inputs[2], pipe.AliasedPipeInput))
        assert.is.equal("in1", blk.inputs[1].name)
        assert.is.equal("in2", blk.inputs[2].name)
        assert.is.equal(1, #blk.outputs)
        assert.is_true(object.isinstanceof(blk.outputs[1], pipe.AliasedPipeOutput))
        assert.is.equal("out", blk.outputs[1].name)

        -- Test blocks for composition

        local TestBlock1 = block.factory("TestBlock1")
        function TestBlock1:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {})
        end

        local TestBlock2 = block.factory("TestBlock2")
        function TestBlock2:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {})
        end

        local TestBlock3 = block.factory("TestBlock3")
        function TestBlock3:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.Integer32Type)})
        end

        local b1 = TestBlock1()
        local b2 = TestBlock2()
        local b3 = TestBlock3()

        -- Check valid connections

        blk:connect(blk, "in1", b1, "in")
        blk:connect(blk, "in2", b2, "in")
        blk:connect(blk, "out", b3, "out")

        assert.is.equal(b1.inputs[1], blk.inputs[1].real_input)
        assert.is.equal(b2.inputs[1], blk.inputs[2].real_input)
        assert.is.equal(b3.outputs[1], blk.outputs[1].real_output)

        -- Check invalid connections

        local blk = radio.CompositeBlock()

        blk:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.Float32Type)}, {block.Output("out", radio.Integer32Type)})

        -- Invalid pipe direction
        assert.has.errors(function () blk:connect(blk, "out", b1, "in") end)
        assert.has.errors(function () blk:connect(blk, "in1", b3, "out") end)

        -- Duplicate input connection
        blk:connect(blk, "in1", b1, "in")
        assert.has.errors(function () blk:connect(blk, "in1", b2, "in") end)
        assert.has.errors(function () blk:connect(b2, "in", blk, "in1") end)

        -- Duplicate output connection
        local b4 = TestBlock3()
        blk:connect(blk, "out", b3, "out")
        assert.has.errors(function () blk:connect(blk, "out", b4, "out") end)
        assert.has.errors(function () blk:connect(b4, "out", blk, "out") end)
    end)

    it("crawl connections", function ()
        --[[

                                Composite3
                         Composite1      Composite2
              [0] - [  [ [A] - [B] ] - [ [A] - [B] ] - [1]

        --]]

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local c1 = radio.CompositeBlock()
        local c1a = TestBlock()
        local c1b = TestBlock()
        c1:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        c1:connect(c1a, c1b)
        c1:connect(c1, "in", c1a, "in")
        c1:connect(c1, "out", c1b, "out")

        local c2 = radio.CompositeBlock()
        local c2a = TestBlock()
        local c2b = TestBlock()
        c2:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        c2:connect(c2a, c2b)
        c2:connect(c2, "in", c2a, "in")
        c2:connect(c2, "out", c2b, "out")

        local c3 = radio.CompositeBlock()
        c3:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
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
            [c2a] = true, [c2b] = true, [b1] = true
        }

        local expected_connections = {
            [c1a.inputs[1]] = b0.outputs[1], [c1b.inputs[1]] = c1a.outputs[1],
            [c2a.inputs[1]] = c1b.outputs[1], [c2b.inputs[1]] = c2a.outputs[1],
            [b1.inputs[1]] = c2b.outputs[1]
        }

        local blocks, connections = composite._crawl_connections(top._connections)

        assert.is.equal(6, util.table_length(blocks))
        assert.is.equal(5, util.table_length(connections))
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
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestSumBlock()
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
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestSumBlock()
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
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestSumBlock()
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

    it("build execution order", function ()
        --[[
            -- [1] -- [2] -- [3] -- [4] -- [5] --
                              | \
                   -- [6] -- [7] \- [8] -- [9] --
        ]]--


        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local top = radio.CompositeBlock()
        local b1 = TestBlock()
        local b2 = TestBlock()
        local b3 = TestSumBlock()
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

        -- Check execution order
        local dependency_graph = composite._build_dependency_graph(top._connections)
        local execution_order = composite._build_execution_order(dependency_graph)

        assert.is_true(util.array_find(execution_order, b1) < util.array_find(execution_order, b2))
        assert.is_true(util.array_find(execution_order, b2) < util.array_find(execution_order, b3))
        assert.is_true(util.array_find(execution_order, b3) < util.array_find(execution_order, b4))
        assert.is_true(util.array_find(execution_order, b4) < util.array_find(execution_order, b5))
        assert.is_true(util.array_find(execution_order, b6) < util.array_find(execution_order, b7))
        assert.is_true(util.array_find(execution_order, b7) < util.array_find(execution_order, b3))
        assert.is_true(util.array_find(execution_order, b3) < util.array_find(execution_order, b8))
        assert.is_true(util.array_find(execution_order, b8) < util.array_find(execution_order, b9))
    end)

    it("running errors", function ()
        local TestSource = block.factory("TestSource")
        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestBlock = block.factory("TestBlock")
        function TestBlock:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.ComplexFloat32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local TestSink = block.factory("TestSink")
        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.ComplexFloat32Type)}, {})
        end

        -- Unconnected inputs
        local top = radio.CompositeBlock()
        local b0 = TestBlock()
        local b1 = TestSink()
        top:connect(b0, b1)

        assert.has.errors(function () top:_prepare_to_run() end)

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSumBlock()
        local b2 = TestSink()
        top:connect(b0, "out", b1, "in1")
        top:connect(b1, "out", b2, "in")

        assert.has.errors(function () top:_prepare_to_run() end)

        -- No compatible signatures

        local TestSumBlock = block.factory("TestSumBlock")
        function TestSumBlock:instantiate()
            self:add_type_signature({block.Input("in1", radio.ComplexFloat32Type), block.Input("in2", radio.Float32Type)}, {block.Output("out", radio.ComplexFloat32Type)})
        end

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSource()
        local b2 = TestSumBlock()
        local b3 = TestSink()
        top:connect(b0, "out", b2, "in1")
        top:connect(b1, "out", b2, "in2")
        top:connect(b2, "out", b3, "in")

        assert.has.errors(function () top:_prepare_to_run() end)

        -- Initialization error

        function TestSink:initialize()
            error('foobar')
        end

        local top = radio.CompositeBlock()
        local b0 = TestSource()
        local b1 = TestSink()
        top:connect(b0, b1)

        assert.has.errors(function () top:_prepare_to_run() end)
    end)
end)
