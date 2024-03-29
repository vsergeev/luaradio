* v0.11.0 - 11/11/2022
    * Application changes
        * Fix wavfile output instantiation error caused by undefined channel
          count.
        * Fix portaudio output instantiation error caused by undefined channel
          count.
    * Core changes
        * Add successful exit return value to `stop()` and `wait()` methods of
          CompositeBlock.
    * C API changes
        * Add successful exit return parameter to `luaradio_stop()` and
          `luaradio_wait()` functions.
    * Documentation changes
        * Update Ubuntu and Debian/Raspbian prerequisites in installation
          guide.
    * Contributors
        * @abutcher-gh - 8c56329
        * Jay Sissom (@jsissom) - 6519586
        * Mark Hills (@hills) - eabf21c

* v0.10.0 - 06/09/2021
    * Application changes
        * Add built-in applications with rx_raw, rx_wbfm, rx_nbfm, rx_am,
          rx_ssb, rx_rds, rx_ax25, rx_pocsag, rx_ert, and iq_converter.
    * Block changes
        * Refactor to use PipeMux in ThrottleBlock and HackRFSink.
        * Add support for v3 API (libsdrplay_api) to SDRplaySource.
        * Refactor title option into options table and add timestamp option for
          PrintSink.
        * Implement `tostring()` for AX25FrameType, POCSAGMessageType,
          and RDSPacketType types.
        * Fix spurious warning about block terminated on shutdown for
          AirspySource.
        * Fix missing error check for set gain mode and fix typo in set gain
          error message in BladeRFSource.
        * Default to autogain if no manual gain specified in RtlSdrSource and
          UHDSource.
    * Composite changes
        * Add RDSDecoderBlock to flow graph of RDSReceiver.
    * Runner changes
        * Add built-in application support.
    * Core changes
        * Add optional count argument to `read()` in PipeMux.
        * Add new helper functions `parse_args()`, `format_options()`,
          `array_concat()`, `array_map()`, `table_extend()`, `table_keys()`,
          and `table_values()`.
        * Add built-in application framework.
    * Documentation changes
        * Fix minor typos in a few docstrings.
        * Add PipeMux and ControlSocket description to Architecture document.
        * Add Applications document.

* v0.9.1 - 01/08/2021
    * Block changes
        * Fix spurious warning about downstream block termination on shutdown
          in RtlSdrSource.
    * Core changes
        * Fix flow graph shutdown handling on Mac OS X due to missing
          `sigtimedwait()`.

* v0.9.0 - 01/04/2021
    * Block additions
        * PulseMatchedFilterBlock
        * PulseAmplitudeModulatorBlock
        * QuadratureAmplitudeModulatorBlock
        * BladeRFSource
        * BladeRFSink
    * Block changes
        * Fix support for Lua file handles with PrintSink and BenchmarkSink.
        * Add support for optional reporting title to PrintSink and
          BenchmarkSink.
    * Core changes
        * Refactor read and write multiplexing of Pipes into the PipeMux class.
        * Add control sockets to blocks to implement graceful shutdown and to
          support an asynchronous control interface in the future.
        * Reimplement flow graph stop with control sockets for faster and more
          graceful shutdown.
        * Add automatic termination of unresponsive block processes to flow
          graph stop.
        * Fix blocking in flow graph wait when flow graph has already
          terminated or when running multiple flow graphs.
    * Documentation changes
        * Add BladeRF and PortAudio to Supported Hardware document.
    * Website changes
        * Improve reference manual layout and navigation.
        * Improve sidebar position and layout.

* v0.8.0 - 10/22/2020
    * Block additions
        * FrequencyModulatorBlock
        * ManchesterMatchedFilterBlock
        * PreambleSamplerBlock
        * IDMFramerBlock
        * SCMFramerBlock
        * SCMPlusFramerBlock
    * Composite additions
        * ERTReceiver
    * Block changes
        * Add file locking to JSONSink to support interleaved writes to the
          same file from multiple instances of the sink.
        * Add alternative library name candidates to PortAudioSource,
          PortAudioSink, PulseAudioSource, PulseAudioSink for better user
          experience on Debian-based platforms.
    * Type changes
        * Add `tobytes()` helper function to the Bit type to convert a Bit
          vector to bytes.
        * Add `tostring()` helper function to the Bit type to format a Bit
          vector as a string.
    * Core changes
        * Add support for trying multiple shared library name candidates in FFI
          library loads.
        * Add alternative library name candidates for liquid-dsp, VOLK, and
          FFTW3 for better user experience on Debian-based platforms.
        * Add support for copying the input data type to the output in block
          type signatures with the `"copy"` sentinel.
        * Enforce explicit block connections are specified with the output port
          first and the input port second.
        * Refactor hierarchical block functionality of CompositeBlock.
            * Add support for type signature differentiation of hierarchical
              blocks.
            * Add support for the `initialize()` hook for hierarchical blocks,
              allowing additional initialization based on the sample rates and
              differentiated type signatures of internal blocks.
            * Improve type validation of aliased ports in hierarchical blocks.
        * Improve the string representation of block objects during various
          connectivity stages (unconnected, differentiated, connected).
    * Build changes
        * Add Lua module installation target to Makefile.
    * Documentation changes
        * Update CompositeBlock internals with hierarchical block functionality
          refactoring in architecture document.
        * Add Lua module installation option to installation guide.
        * Add note about LuaJIT 2.1.0-beta3 embedded bytecode loading bug to
          installation guide.
        * Improve description of shared library in embedding guide.
    * Website changes
        * Improve formatting of headers and the sidebar.
    * Contributors
        * Jonas Rudloff (@kokjo) - eb5bc68, 4a16f57, 36ce479
        * Paul Harrington (@phrrngtn) - for discussion, many IQ samples, and
          testing of the ERTReceiver composite.

* v0.7.0 - 04/29/2020
    * Block additions
        * PortAudioSource
        * AirspyHFSource
    * Block changes
        * Add option for direct sampling mode to RtlSdrSource.
        * Fix feedback loop causing diminishing throughput in ThrottleBlock.
        * Use `FFTW_ESTIMATE` in fftw DFT/IDFT initialization to reduce startup
          time on certain platforms (e.g. Raspberry Pi 3) when using FFT
          accelerated FIRFilterBlock.
    * Core changes
        * Improve string representation for core C structure types.
        * Add `type_name` property to core types, CStructType factory, and
          ObjectType factory for use in error and debug reporting.
        * Disable call operator for constructed block instances.
        * Fix method registration with `methods` table argument in ObjectType
          factory function.
        * Enforce linear connections between blocks have exactly one output and
          input port.
        * Improve error reporting in type signature differentiation with port
          names and types.
        * Improve flow graph debug reporting with sample rates and data types.
        * Add optional `count` argument to Pipe read().
    * Documentation changes
        * Add macOS MacPorts package to installation guide and README.
        * Improve dependency installation instructions in installation guide
          and README.
        * Add support for `@property` docstring in reference manual.
        * Add mailing list link (https://groups.io/g/luaradio) to README and
          website.
        * Add Airspy HF+ Dual Port and Discovery to Supported Hardware
          document.

* v0.6.1 - 03/07/2020
    * Block changes
        * Fix gnuplot check under lua52compat LuaJIT for gnuplot plotting
          sinks.
        * Update C API (v0.8) to fix block crash for SoapySDRSource and
          SoapySDRSink.
        * Add library and ABI version reporting to debug dump for
          SoapySDRSource and SoapySDRSink.
        * Migrate to new callback based API (v2.13) for SDRplaySource.
        * Update C API (v3.15.0.0) for UHDSource and UHDSink.
        * Add library and ABI version reporting to debug dump for UHDSource and
          UHDSink.
        * Clean up manual gain warnings under autogain setup for UHDSource.
        * Add device reporting to debug dump for RtlSdrSource.
        * Make FFI cdefs more consistent with public APIs for HackRFSink,
          HackRFSource, UHDSource, UHDSink, and AirspySource.
    * Build changes
        * Improve LuaJIT library and executable discovery in Makefile.
    * Documentation changes
        * Fix examples in docstrings for several gnuplot plotting sinks.
        * Update and simplify instructions in installation guide.
        * Add macOS Homebrew package to installation guide.
    * Website changes
        * Update hardware and software suggestions in New to SDR guide.
    * Contributors
        * Jakob L. Kreuze (@TsarFox) - 1dc9f7e

* v0.6.0 - 12/12/2019
    * Block additions
        * JSONSource
        * NetworkClientSource
        * NetworkServerSource
        * NetworkClientSink
        * NetworkServerSink
    * Block changes
        * Add format_utils with binary sample format conversion tables.
        * Add network_utils with network server and client utility classes.
        * Refactor several file sources and sinks to use format_utils:
          IQFileSource, RealFileSource, WAVFileSource, IQFileSink,
          RealFileSink, WAVFileSink.
        * Move common shared utilities to radio/utilities/ folder.
        * Improve memory copies in several blocks: DelayBlock, FIRFilterBlock,
          HilbertTransformBlock, ThrottleBlock, GnuplotSpectrumSink,
          GnuplotWaterfallSink, AX25FramerBlock, POCSAGFramerBlock,
          RDSFramerBlock.
        * Remove stdout debug prints from PulseAudioSource.
        * Fix partial reads in RawFileSource.
        * Fix error lookups in UHDSource and UHDSink.
    * Core changes
        * Factor common FFI cdefs out of blocks and into platform module.
        * Improve memory copies and clears in vector module.
        * Default construct elements on ObjectVector instantiation in vector
          module.
        * Remove radio.core.util export from top namespace.
        * Add radio.core.vector export to top namespace.
        * Fix namespacing of callback function in async module.
        * Add library version lookups to platform module.
    * Runner changes
        * Add library versions to platform dump.
    * Test changes
        * Fix Python test code generators for DecimatorBlock and top level test
          with scipy.signal.decimate() API change.
        * Rename code generated tests with .gen.lua suffix.
        * Simplify unit test file structure by moving Python test code
          generators from tests/generator/ folder to alongside generated tests.
        * Add `.busted` configuration to simplify unit testing invocation.
        * Add temporarily increased epsilon conditioned on liquid-dsp
          acceleration for FrequencyTranslatorBlock and TunerBlock tests to
          accommodate NCO changes in library.
    * Benchmark changes
        * Add library versions to platform reporting in LuaRadio benchmark
          results.
    * Documentation changes
        * Fix formatting of argument types in reference manual.
        * Add README to embed/ folder.
        * Add busted install instructions to project README and tests README.
        * Simplify busted invocation in project README, tests README, and
          Creating Blocks document.
        * Add REPL install instructions and FFI development tips to Creating
          Blocks document.
        * Update links in Creating Blocks, Comparison to GNU Radio, and
          Supported Hardware documents.
    * Thirdparty changes
        * Bump lua-MessagePack version to 0.5.2.
        * Bump json.lua version to 0.1.2.
    * Website changes
        * Merge luaradio.io website subproject into website/ folder.
        * Update luaradio.io website URL with https.

* v0.5.1 - 09/03/2018
    * Block changes
        * Fix symbol issue with libSoapySDR library load on Mac OS X in
          SoapySDRSource and SoapySDRSink.
        * Add biastee and bandwidth options to RtlSdrSource.
    * Documentation changes
        * Fix minor typos in a few docstrings.
        * Fix source in flow graph for benchmark example.
        * Rewrite reference manual generator in Python.
        * Update docstrings for new reference manual generator.
    * Contributors
        * Ralf Biedert (@ralfbiedert) - 49d66027
        * Ralf Biedert (@ralfbiedert) - 824057ba
        * Phil (@philharrisathome) - 68d6a838

* v0.5.0 - 11/21/2016
    * Block additions
        * UHDSource
        * UHDSink
        * NopSink
        * NopBlock
    * Block changes
        * Fix ThrottleBlock implementation with adaptive delay.
        * Fix error reporting during initialization in PulseAudioSource and
          PulseAudioSink.
        * Fix settings table argument in SoapySDRSource and SoapySDRSink.
        * Rename NullSource to ZeroSource.
    * Core changes
        * Add time_us() helper to platform module.
    * Documentation changes
        * Fix minor typos in a few docstrings.
        * Improve wording in several documents.
        * Update supported hardware document with USRP support.
    * Contributors
        * Daniel Von Fange - 22932b1

* v0.4.0 - 08/31/2016
    * Block additions
        * HackRFSink
        * SoapySDRSource
        * SoapySDRSink
        * PulseAudioSource
        * InterleaveBlock
        * DeinterleaveBlock
    * Block changes
        * Fix I/Q sample conversion in HackRFSource.
        * Add FFT overlap-save implementation to FIRFilterBlock.
        * Improve performance of real to complex DFT in spectrum_utils.
        * Refactor PSD into separate class in spectrum_utils.
        * Add IDFT to spectrum_utils.
        * Add error handling for process pipe writes in gnuplot plotting sinks.
        * Fix default window type and columns values in GnuplotWaterfallSink.
    * Benchmark changes
        * Add FFT-based FIR filters to benchmarks.
        * Adjust filter tap lengths in benchmarks.
    * Core changes
        * Improve error handling and traceback when a downstream block crashes.
    * Documentation changes
        * Fix minor typos in a few docstrings.
        * Update supported hardware document.

* v0.3.0 - 07/28/2016
    * Block additions
        * AGCBlock
        * PowerSquelchBlock
        * VaricodeDecoderBlock
    * Composite additions
        * BPSK31Receiver
    * C API changes
        * Add stack traceback to error messages.
    * Documentation changes
        * Add Ubuntu install instructions to installation guide.
        * Fix minor typos and wording in a few documents and docstrings.
    * Example changes
        * Replace constant gain with automatic gain control in
          rtlsdr_am_envelope, rtlsdr_am_synchronous, and rtlsdr_ssb examples.

* v0.2.0 - 07/16/2016
    * Block additions
        * AirspySource
        * HackRFSource
        * SDRplaySource
    * Block changes
        * Add proper device close to RtlSdrSource.
    * Core changes
        * Add asynchronous callback wrapper to support callbacks from threads
          and signal handlers.
    * Documentation changes
        * Add Supported Hardware document.
        * Add Homebrew install instructons to installation guide.
    * Contributors
        * Martin Müller - 354cd5e0
        * Dominic Spill - 26bcbf72
        * Special thanks to @zeryl, @rxseger, @dominicgs for testing and fixing
          the HackRF source block.

* v0.1.2 - 07/09/2016
    * C API changes
        * Use /usr/local as default prefix for installation in Makefile.
        * Extract version numbers from radio package rather than git tag in
          Makefile.
    * Examples changes
        * Remove setup-specific RtlSdrSource frequency correction settings from
          examples, which were accidentally committed.
    * Documentation changes
        * Fix type signatures example figure.
        * Fix minor typos and wording in a few documents and docstrings.
        * Qualify a few points in the Comparison to GNU Radio document.
        * Add prerequisites and dependencies to installation guide.
        * Add contributing document.
    * Contributors
        * Kevin Mehall - 8a859261

* v0.1.1 - 07/03/2016
    * Block changes
        * Add device index option to RtlSdrSource.
        * Choose default RF gain from dongle supported gains in RtlSdrSource.
    * C API changes
        * Look up lua C module install path instead of presuming it in
          Makefile.
    * Example changes
        * Fix tuner filter bandwidth in rtlsdr_rds.
    * Documentation changes
        * Make types bold in type signatures example figure.
        * Improve wording in Comparison to GNU Radio document.

* v0.1.0 - 07/02/2016
    * Initial release.

* (Prototype) v0.0.20 - 07/01/2016
    * Block additions
        * ManchesterDecoderBlock
    * Block changes
        * Re-order initialization in RtlSdrSource to fix "PLL not locked"
          warning.
        * Move type conversion blocks from Miscellaneous to their own category
          in their block docstrings.
    * Composite changes
        * Improve bit sampling and decoding, and simplify to non-coherent BPSK
          demodulation in RDSReceiver.
    * C API changes
        * Add install target to Makefile.
        * Add version number fallbacks to Makefile for building out of git
          tree.
        * Fix shared library build on Mac OS X.
        * Improve portability of rds-timesync example to support Mac OS X.
        * Rename fmradio example to fm-radio for consistency.
    * Runner changes
        * Add support for running scripts from standard in.
    * Documentation changes
        * Resize all figures to under 800px.
        * Simplify instructions in installation guide.
        * Improve wording in all documents.
        * Improve formatting and wording in several docstrings.
        * Improve formatting of reference manual.
    * Benchmark changes
        * Bump number of trials from 3 to 5.
        * Add standard deviation computation.
        * Shorten benchmark names.
    * Example changes
        * Improve bit sampling and decoding, and simplify to non-coherent BPSK
          demodulation in rtlsdr_rds.
        * Improve plot range of RF spectrum in rtlsdr_ssb.
        * Improve variable names in several examples.
        * Rearrange code and add section comments for clarity in all examples.

* (Prototype) v0.0.19 - 06/04/2016
    * Documentation changes
        * Add packaged third-party modules licenses to LICENSE file.
        * Add docstrings throughout codebase and blocks.
        * Add reference manual generator.
        * Add documents:
            * Reference Manual
            * Installation
            * Creating Blocks
            * Embedding LuaRadio
            * Architecture
            * Comparison to GNU Radio
        * Add tests README.
        * Add examples README.
        * Add project README.

* (Prototype) v0.0.18 - 06/04/2016
    * Block additions
        * RealToComplexBlock
        * AddConstantBlock
        * SinglepoleLowpassFilterBlock
        * SinglepoleHighpassFilterBlock
        * FMPreemphasisFilterBlock
    * Block changes
        * Add return codes to error messages in RtlSdrSource.
        * Improve performance of RtlSdrSource by using `rtlsdr_read_async()`.
        * Change gain argument to modulation index in
          FrequencyDiscriminatorBlock.
        * Add filename and file object support to BenchmarkSink.
        * Add periodic human-readable reporting to BenchmarkSink.
        * Refactor FMDeemphasisFilterBlock to use SinglepoleLowpassFilterBlock.
        * Rearrange optional nyquist frequency argument order in filter blocks.
        * Fix overflow for sample values of 1.0 in WAVFileSink.
        * Add sampling interval to BinaryPhaseCorrectorBlock to reduce
          computation.
        * Use line style 1 for plotting in GnuplotPlotSink, GnuplotXYPlotSink,
          GnuplotSpectrumSink.
        * Add argument assertions to all blocks.
        * Refactor all blocks to use persistent output sample vectors.
    * Composite changes
        * Remove constant audio gain block from AMEnvelopeDemodulator,
          AMSynchronousDemodulator, and SSBDemodulator.
        * Add DC rejection filter for carrier to AMEnvelopeDemodulator and
          AMSynchronousDemodulator.
        * Add argument assertions to all composites.
    * Example changes
        * Add iqfile_converter example.
        * Add DC rejection filter for carrier to rtlsdr_am_envelope and
          rtlsdr_am_synchronous.
        * Remove autogain setting from RTL-SDR source in rtlsdr_wbfm_mono,
          rtlsdr_wbfm_stereo, rtlsdr_rds examples.
        * Make tune offsets consistent across examples.
        * Make plot ranges consistent across examples.
        * Add headless running support to all examples.

* (Prototype) v0.0.17 - 06/03/2016
    * Core changes
        * Fix deadlock in synchronous read of multiple pipes, when a slower
          input pipe has an indirect dependency on a faster input pipe because
          it shares a common upstream writer.
        * Enforce all block input rates match before running in CompositeBlock.
        * Enforce inputs/outputs names match previous type signatures in Block.
        * Close unneeded file descriptors in block process after forking in
          CompositeBlock.
        * Add protected call wrapper to block running in CompositeBlock.
        * Add `status()` method to CompositeBlock.
        * Add `__tostring()` metamethod to Vector and ObjectVector.
        * Rename `type` property to `data_type` in Vector and ObjectVector.
        * Return self in `resize()`, `append()` methods of Vector and
          ObjectVector.
        * Refactor `run()` method in Block.
        * Rename `get_input_types()`, `get_output_types()` methods to
          `get_input_type()`, `get_output_type()` in Block.
        * Improve error messages in Block.
        * Improve debug and error messages in CompositeBlock.
        * Add CompositeBlock control (status, wait, stop) unit tests.
    * C API changes
        * Rename context type from `radio_t` to `luaradio_t`.
        * Add `luaradio_status()` function to wrap CompositeBlock `status()`.
        * Add `luaradio_get_state()` function to get Lua state.
        * Refactor and improve C API unit test.
        * Clean up fmradio and rds-timesync examples.
    * Block changes
        * Rename RDSFrameBlock to RDSFramerBlock.
        * Rename RDSDecodeBlock to RDSDecoderBlock.
        * Rename AX25FrameBlock to AX25FramerBlock.
        * Rename POCSAGFrameBlock to POCSAGFramerBlock.
        * Rename POCSAGDecodeBlock to POCSAGDecoderBlock.
        * Rename SumBlock to AddBlock.
    * Benchmark changes
        * Reduce factors in downsampler and upsampler benchmarks.
        * Increase buffer sizes in several file source benchmarks.

* (Prototype) v0.0.16 - 05/03/2016
    * Simplify class module namespacing, including blocks and basic types.
    * Improve basic type names.
    * Remove unused Integer32 basic type.
    * Remove Pipe `vmsplice()` feature, which was problematic with blocks that
      use persistent sample buffers.
    * Change Pipe backend from UNIX pipes to UNIX sockets.
    * Eliminate sleeping in CompositeBlock `wait()`.
    * Add `version_info` table to radio package.
    * Add liquid-dsp library loading to platform module.
    * Add liquid-dsp implementation to the following blocks and classes:
        * FIRFilterBlock
        * IIRFilterBlock
        * HilbertTransformBlock
        * FrequencyTranslatorBlock
        * DFT in spectrum_utils
    * Add file object support to the following sources and sinks:
        * IQFileSource
        * RawFileSource
        * RealFileSource
        * WAVFileSource
        * IQFileSink
        * RawFileSink
        * WAVFileSink
        * RealFileSink
    * Fix infinite loop bug on invalid frame sync codeword in POCSAGFrameBlock.
    * Add "Multiply (Real-valued)" benchmark to benchmark suites.
    * Add SIGINT handling to LuaRadio benchmark suite.
    * Reduce number of filter taps in most modulation, demodulation, and
      receiver composite blocks.
    * Reduce number of filter taps in most examples.
    * Change decimators to downsamplers in several examples, where additional
      filtering before downsampling wasn't needed.

* (Prototype) v0.0.15 - 04/18/2016
    * Add BenchmarkSink block.
    * Remove old LuaRadio and GNURadio benchmark scripts.
    * Add more comprehensive LuaRadio and GNURadio benchmark suites.
    * Improve performance of arg() and abs() methods of ComplexFloat32Type.
    * Improve performance of several blocks:
        * DelayBlock
        * DifferentialDecoderBlock
        * FrequencyDiscriminatorBlock
        * SignalSource
        * FIRFilterBlock
        * HilbertTransformBlock
    * Fix unit tests descriptions for DelayBlock and IIRFilterBlock.

* (Prototype) v0.0.14 - 04/15/2016
    * Fix resizing zero length vectors.
    * Add get_input_types() and get_output_types() methods to Block base class.
    * Simplify repeated code in some blocks with Block base class methods.
    * Improve portability of several C definitions with typedefs.
    * Fix C error message construction throughout the codebase.
    * Fix clean up in several sinks on early exit before process() is run.
    * Add install hints to error messages for library soft dependencies.
    * Add CPU count, CPU model, LuaJIT version lookups to platform module and
      the luaradio runner platform dump.
    * Fix RtlSdrSource initialization on Mac OS X platform.
    * Rename RandomSource to UniformRandomSource and add support for custom
      range and seed.

* (Prototype) v0.0.13 - 04/09/2016
    * Add luaradio executable with help, version, platform, and verbosity options.
    * Add version string and version number to radio package.
    * Add version string, version number, and version info to C API.
    * Add LuaJIT interpreter check to radio package init.
    * Add debug module for gated printing of debug messages.
    * Use debug module instead of io.stderr in several blocks.
    * Remove C luaradio executable.
    * Rename demos/ to examples/.
    * Rename embed/demos/ to embed/examples/.
    * Update C API unit test.
    * Fix running certain composite block unit tests on FreeBSD.
    * Refactor Python unit test generators and split them into separate files.

* (Prototype) v0.0.12 - 04/07/2016
    * Rename wbfm_rtlsdr demo to rtlsdr_wbfm_mono.
    * Rename rds_rtlsdr demo to rtlsdr_rds.
    * Improve plotting, variable names, and performance of rtlsdr_wbfm_mono and rtlsdr_rds demos.
    * Add new protocol blocks:
        * AX25FrameBlock
        * POCSAGFrameBlock
        * POCSAGDecodeBlock
    * Refactor RDSFrameBlock and RDSDecodeBlock.
    * Add new demos:
        * rtlsdr_wbfm_stereo
        * rtlsdr_nbfm
        * rtlsdr_am_envelope
        * rtlsdr_am_synchronous
        * rtlsdr_ssb
        * wavfile_ssb_modulator
        * rtlsdr_ax25
        * rtlsdr_pocsag
    * Add new composite blocks:
        * NBFMDemodulator
        * AMEnvelopeDemodulator
        * AMSynchronousDemodulator
        * SSBDemodulator
        * SSBModulator
        * WBFMMonoDemodulator
        * WBFMStereoDemodulator
        * RDSReceiver
        * AX25Receiver
        * POCSAGReceiver
    * Use composite blocks in rds-timeync and fmradio embed demos.
    * Improve unit tests.

* (Prototype) v0.0.11 - 04/01/2016
    * Fix execution of composite blocks with intermediate sinks.
    * Add support for aliasing a composite block input to multiple block inputs.
    * Add vector_from_array() vector constructor to ObjectType.
    * Move bits_to_number() helper function to BitType.tonumber() static method.
    * Simplify DecimatorBlock, InterpolatorBlock, RationalResamplerBlock constructors.
    * Fix scaling in InterpolatorBlock and RationalResamplerBlock.
    * Fix low pass filter cutoff in TunerBlock.
    * Fix output data type in FloatToComplexBlock type signature.
    * Fix output data type in RawFileSource type signature.
    * Fix size type bug in RawFileSource.
    * Fix file repeat in WAVFileSource.
    * Add RF gain and frequency correction options to RtlSdrSource.
    * Add magnitude reference level option to GnuplotSpectrumSink.
    * Add min/max magnitude options to GnuplotWaterfallSink.
    * Disable file stream buffering in RawFileSink, JSONSink, and PrintSink.
    * Add filename and file descriptor support to PrintSink.
    * Add invert option to DifferentialDecoderBlock.
    * Normalize passband gain to 1.0 in FIR window design functions.
    * Add support for specifying a normalized nyquist frequency to filter blocks.
    * Add support for complex taps to FIRFilterBlock.
    * Add complex bandpass and bandstop FIR window design functions.
    * Add new signal blocks:
        * ComplexBandpassFilterBlock
        * ComplexBandstopFilterBlock
        * ComplexConjugateBlock
        * ZeroCrossingClockRecoveryBlock
    * Add new sink blocks:
        * PortAudioSink
    * Improve unit tests.
    * Add composite block unit tests.
    * Improve namespacing with package inits for blocks and composites.
    * Simplify block imports in composite blocks.

* (Prototype) v0.0.10 - 03/10/2016
    * Add abs_squared() method to ComplexFloat32Type.
    * Add cosine, sine, square, triangle, sawtooth, and constant real signals to SignalSource.
    * Add file repeat option to IQFileSource, RealFileSource, WAVFileSource, RawFileSource.
    * Add support for multiple channels to PulseAudioSink.
    * Add support for other data types to NullSource and RandomSource.
    * Add support for generating periodic windows to window utilities.
    * Add FFTW3 library and feature flag to platform module.
    * Add DFT and PSD spectrum utilities with Lua, VOLK, and FFTW3 implementations.
    * Add new signal blocks:
        * SubtractBlock
        * ComplexToImagBlock
        * ComplexToFloatBlock
        * FloatToComplexBlock
        * ComplexMagnitudeBlock
        * ComplexPhaseBlock
        * AbsoluteValueBlock
        * MultiplyConstantBlock
        * UpsamplerBlock
        * ThrottleBlock
    * Add new composite blocks:
        * InterpolatorBlock
        * RationalResamplerBlock
    * Add gnuplot-based plotting sinks:
        * GnuplotPlotSink
        * GnuplotXYPlotSink
        * GnuplotSpectrumSink
        * GnuplotWaterfallSink
    * Fix numerical stability problem in FrequencyTranslatorBlock and SignalSource.
    * Improve unit tests.
    * Add plots to RDS and WBFM demos.

* (Prototype) v0.0.9 - 03/02/2016
    * Simplify type imports in blocks.
    * Fix single process execution to call block cleanup() after finish.
    * Fix block initialization order.
    * Extend file source and sink blocks to:
        * IQFileSource / IQFileSink
        * RealFileSource / RealFileSink
        * RawFileSource / RawFileSink
        * WAVFileSource / WAVFileSink
    * Improve unit tests.
    * Reorganize package init for readability.

* (Prototype) v0.0.8 - 02/28/2016
    * Add libluaradio library with a C API to the LuaRadio runtime.
    * Add fmradio and rds-timesync demos for libluaradio.
    * Add standalone luaradio interpreter.

* (Prototype) v0.0.7 - 02/26/2016
    * Add platform module with platform-specific constants and allocator.
    * Handle missing library gracefully in RtlSdrSource and PulseAudioSink.
    * Add portable implementation of Pipe for non-Linux platforms.
    * Add portable Lua implementations of signal processing blocks for Volk-less platforms.
    * Fix other minor portability issues.
    * This release adds support for FreeBSD and Mac OS X platforms.

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
