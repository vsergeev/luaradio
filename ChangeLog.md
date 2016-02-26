* (Prototype) v0.0.6 - 02/25/2016
    * Rename some blocks for consistency.
    * Return nil on EOF from source blocks instead of exiting.
    * Add File[IQ]DescriptorSource blocks and derive File[IQ]Source blocks from
      them.
    * Fix s32 format in File[IQ]DescriptorSource.
    * Fix bnot() operator in BitType.
    * Fix overflow/underflow handling in Integer32Type.
    * Use POSIX pipes in single process execution.
    * Add more argument and behavior assertions to Block and CompositeBlock.
    * Add unit tests.

* (Prototype) v0.0.5 - 02/12/2016
    * Change CompositeBlock run() to use multiprocesses by default.
    * Use CStructType factory to build all basic types.
    * Add tostring() support to Block.
    * Handle pipe EOF in Block run() to stop processing and clean up.
    * Update benchmarks.
    * Rename <Name>SourceBlock to <Name>Source and <Name>SinkBlock to
      <Name>Sink.

* (Prototype) v0.0.4 - 02/12/2016
    * Add support for functions as candidate input types in block type
      signatures.
    * Add support for variable length type serialization with ProcessPipe.
    * Add ObjectType factory custom Lua object types (serialized with
      MessagePack).
    * Add JsonSinkBlock and update the RDS demo to use it.

* (Prototype) v0.0.3 - 02/11/2016
    * Add CStructType factory for custom cstruct types.
    * Add Vector class and resize(), append() methods.
    * Add necessary blocks to implement RDS demodulator / decoder demo.
    * Add TunerBlock and DecimatorBlock composite blocks.
    * Update demos to use composite blocks.

* (Prototype) v0.0.2 - 02/08/2016
    * Add hierarchical block support to CompositeBlock.
    * Add start(), stop(), wait(), run() controls to CompositeBlock.
    * Add support for linear chain shortcut to CompositeBlock connect() (e.g.
      connect(b1, b2, b3, ...)).

* (Prototype) v0.0.1 - 02/06/2016
    * Initial prototype with wbfm demo.
