---
layout: default
---

**LuaRadio** is a lightweight, embeddable flow graph signal processing
framework for software-defined radio. It provides a suite of source, sink, and
processing blocks, with a simple API for defining flow graphs, running flow
graphs, creating blocks, and creating data types. LuaRadio is built on
[LuaJIT](http://luajit.org/), has a small binary footprint of under 750 KB
(including LuaJIT), has no external hard dependencies, and is MIT licensed.

LuaRadio can be used to rapidly prototype software radios,
modulation/demodulation utilities, and signal processing experiments.  It can
also be embedded into existing radio applications to serve as a user scriptable
engine for processing samples.

LuaRadio blocks are written in pure Lua, but can use [LuaJIT's
FFI](http://luajit.org/ext_ffi.html) to wrap external libraries, like
[VOLK](http://libvolk.org/),
[liquid-dsp](https://github.com/jgaeddert/liquid-dsp), and others, for
computational acceleration, more sophisticated processing, and interfacing with
SDR hardware.

Use GNU Radio? See [how LuaRadio compares to GNU
Radio](docs/comparison-gnuradio.html).

## Example

<p align="center">
<i>Wideband FM Broadcast Radio Receiver</i>
</p>

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_wbfm_mono_compact.png" />
</p>

``` lua
local radio = require('radio')

radio.CompositeBlock():connect(
    radio.RtlSdrSource(88.5e6 - 250e3, 1102500), -- RTL-SDR source, offset-tuned to 88.5 MHz - 250 kHz
    radio.TunerBlock(-250e3, 200e3, 5),          -- Translate -250 kHz, filter 200 kHz, decimate 5
    radio.FrequencyDiscriminatorBlock(1.25),     -- Frequency demodulate with 1.25 modulation index
    radio.LowpassFilterBlock(128, 15e3),         -- Low-pass filter 15 kHz for L+R audio
    radio.FMDeemphasisFilterBlock(75e-6),        -- FM de-emphasis filter with 75 uS time constant
    radio.DownsamplerBlock(5),                   -- Downsample by 5
    radio.PulseAudioSink(1)                      -- Play to system audio with PulseAudio
):run()
```

Check out some more [examples](examples/) of what you can build with LuaRadio.

## Quickstart

With LuaJIT installed, LuaRadio can be run directly from the repository:

```
git clone https://github.com/vsergeev/luaradio.git
```

```
$ cd luaradio
$ ./luaradio --platform
luajit          LuaJIT 2.0.5
os              Linux
arch            x64
page size       4096
cpu count       4
cpu model       Intel(R) Core(TM) i5-4570T CPU @ 2.90GHz
features
    fftw3f      true    fftw-3.3.8-sse2-avx
    volk        true    2.0 (avx2_64_mmx_orc)
    liquid      true    1.3.2
$
```

LuaRadio is accelerated by the optional libraries
[liquid-dsp](https://github.com/jgaeddert/liquid-dsp),
[VOLK](http://libvolk.org/), and [fftw](http://www.fftw.org/) for real-time
applications. To run the real-time examples, install liquid-dsp or VOLK, and
check that the `liquid` and/or `volk` features are marked `true` in the
platform information.

LuaRadio primarily supports Linux. It also strives to support FreeBSD and Mac
OS X, but real-time support and audio sink support on these platforms is
currently experimental.

Try out one of the [examples](examples/) with an
[RTL-SDR](http://www.rtl-sdr.com/about-rtl-sdr/) dongle:

```
$ ./luaradio examples/rtlsdr_wbfm_mono.lua 91.1e6
```

LuaRadio and all of its examples run great on the Raspberry Pi 3 with Arch
Linux.

See the [Getting Started](docs/getting-started.html) guide for a tutorial on
building your own flow graphs.

