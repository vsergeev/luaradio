# LuaRadio

LuaRadio is a lightweight, embeddable flow graph signal processing framework
for software defined radio, built on [LuaJIT](http://luajit.org/). It provides
a suite of source, sink, and processing blocks, with a simple API for building
flow graphs, running flow graphs, creating blocks, and creating data types. It
has a small binary footprint of under 700 KB (including LuaJIT) and has no
external hard dependencies.

LuaRadio blocks can use [LuaJIT's FFI](http://luajit.org/ext_ffi.html) to wrap
external libraries, like [liquid-dsp](https://github.com/jgaeddert/liquid-dsp),
[libvolk](http://libvolk.org/), and others, for computational acceleration,
more sophisticated processing, and interfacing with SDR hardware.

LuaRadio is easily embeddable with its C API, making it possible to integrate
LuaRadio scripts into existing radio applications, or to build entirely
standalone radio applications and utilities.

LuaRadio is free and permissively licensed (MIT license).

Use GNU Radio? See [how LuaRadio compares to GNU Radio](docs/6.comparison-gnuradio.md).

## Example

##### Wideband FM Mono Receiver Example

<p align="center">
<img src="docs/figures/flowgraph_rtlsdr_wbfm_mono_compact.png" />
</p>

``` lua
local radio = require('radio')

radio.CompositeBlock():connect(
    radio.RtlSdrSource(88.5e6 - 250e3, 1102500), -- RTL-SDR source, offset-tuned to 88.5MHz-250kHz
    radio.TunerBlock(-250e3, 200e3, 5),          -- Translate -250 kHz, filter 200 kHz, decimate by 5
    radio.FrequencyDiscriminatorBlock(1.25),     -- Frequency demodulate with 1.25 modulation index
    radio.LowpassFilterBlock(128, 15e3),         -- Low-pass filter 15 kHz for L+R audio
    radio.FMDeemphasisFilterBlock(75e-6),        -- FM de-emphasis filter with 75 uS time constant
    radio.DownsamplerBlock(5),                   -- Downsample by 5
    radio.PulseAudioSink(1)                      -- Play to system audio with PulseAudio
):run()
```

Check out some more [examples](examples) of what you can build with LuaRadio.

## Quickstart

LuaRadio can be run directly from the repository.

```
git clone git://github.com/vsergeev/luaradio.git
```

``` shell
$ cd luaradio
$ ./luaradio --platform
luajit          LuaJIT 2.0.4
os              Linux
arch            x64
page size       4096
cpu count       4
cpu model       Intel(R) Core(TM) i5-4570T CPU @ 2.90GHz
features
    fftw3f      true
    volk        true
    liquid      true
$
```

LuaRadio is accelerated by the optional libraries
[liquid-dsp](https://github.com/jgaeddert/liquid-dsp),
[libvolk](http://libvolk.org/), and [fftw](http://www.fftw.org/) for real-time
applications. To run the real-time examples, install liquid-dsp or libvolk, and
check that `liquid` or `volk` are marked `true` in the platform information.

LuaRadio primarily supports Linux. It also strives to support FreeBSD and Mac
OS X, but real-time support and audio sink support on these platforms is
currently experimental.

Try out one of the [examples](examples) with an
[RTL-SDR](http://www.rtl-sdr.com/about-rtl-sdr/) dongle:

```
$ ./luaradio examples/rtlsdr_wbfm_mono.lua 91.1e6
```

LuaRadio runs great on the Raspberry Pi 3 with Arch Linux. All of the examples
also run on the Raspberry Pi 3.

See the [Getting Started](docs/2.getting-started.md) guide for a tutorial on
building your own flow graphs.

## Installation

Arch Linux users can install LuaRadio with the AUR package `luaradio`.

See the [Installation](docs/1.installation.md) guide for other installation
methods.

## Documentation

LuaRadio documentation is contained in the [docs](docs) folder.

* 0. [Reference Manual](docs/0.reference-manual.md)
* 1. [Installation](docs/1.installation.md)
* 2. [Getting Started](docs/2.getting-started.md)
* 3. [Creating Blocks](docs/3.creating-blocks.md)
* 4. [Embedding LuaRadio](docs/4.embedding-luaradio.md)
* 5. [Architecture](docs/5.architecture.md)
* 6. [Comparison to GNU Radio](docs/6.comparison-gnuradio.md)

## Project Structure

* [radio/](radio) - Radio package
    * [core/](radio/core) - Core framework
    * [types/](radio/types) - Basic types
    * [blocks/](radio/blocks) - Blocks
        * [sources/](radio/blocks/sources) - Sources
        * [sinks/](radio/blocks/sinks) - Sinks
        * [signal/](radio/blocks/signal) - Signal blocks
        * [protocol/](radio/blocks/protocol) - Protocol blocks
    * [composites/](radio/composites) - Composite blocks
    * [thirdparty/](radio/thirdparty) - Included third-party libraries
    * [init.lua](radio/init.lua) - Package init
* [examples/](examples) - Examples
* [embed/](embed) - Embeddable C library
    * [Makefile](embed/Makefile) - C library Makefile
    * [luaradio.c](embed/luaradio.c) - C API implementation
    * [luaradio.h](embed/luaradio.h) - C API header
    * [examples/](embed/examples) - C API examples
    * [tests/](embed/tests) - C API unit tests
* [benchmarks/](benchmarks/) - Benchmark suites
    * [luaradio_benchmark.lua](benchmarks/luaradio_benchmark.lua) - LuaRadio benchmark suite
    * [gnuradio_benchmark.py](benchmarks/gnuradio_benchmark.py) - GNU Radio benchmark suite
* [docs/](docs) - Documentation
    * [refman/](docs/refman) - Reference manual generator
* [tests/](tests) - Unit tests
    * [generate/](tests/generate/) - Unit test code generators (Python 3)
* [ChangeLog.md](ChangeLog.md) - Change Log
* [README.md](README.md) - This README
* [LICENSE](LICENSE) - MIT License
* [luaradio](luaradio) - `luaradio` runner helper script executable

## Testing

LuaRadio unit tests are run with [busted](http://olivinelabs.com/busted/):

```
busted --lua=luajit --lpath="./?/init.lua" --no-auto-insulate tests/
```

## License

LuaRadio is MIT licensed. See the included [LICENSE](LICENSE) file.

