* (Prototype) v0.0.5 - 02/12/2016
    * Change CompositeBlock run() to use multiprocesses by default.
    * Use CStructType factory to build all basic types.
    * Add tostring() support to Block.
    * Handle pipe EOF in Block run() to stop processing and clean up.
    * Update benchmarks.
    * Rename <Name>SourceBlock to <Name>Source and <Name>SinkBlock to <Name>Sink.

* (Prototype) v0.0.4 - 02/12/2016
    * Add support for functions as candidate input types in block type signatures.
    * Add support for variable length type serialization with ProcessPipe.
    * Add ObjectType factory custom Lua object types (serialized with MessagePack).
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
    * Add support for linear chain shortcut to CompositeBlock connect() (e.g. connect(b1, b2, b3, ...)).

* (Prototype) v0.0.1 - 02/06/2016
    * Initial prototype with wbfm demo.
