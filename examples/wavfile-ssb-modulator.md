---
layout: default
title: WAV File SSB Modulator Example
---

# [`wavfile_ssb_modulator.lua`]({{ site.data.theme.github_url }}/blob/master/examples/wavfile_ssb_modulator.lua)

This example is a file-based
[Single-Sideband](https://en.wikipedia.org/wiki/Single-sideband_modulation)
(SSB) modulator. It takes a single channel WAV file audio input, and produces a
binary IQ file (`f32le` format) output with the single-sideband modulated
audio. This example doesn't use the RTL-SDR at all, but instead demonstrates
how you can build file-based command-line utilities with modulation,
demodulation, decoding, file conversion, etc. flow graphs that run to
completion.

This single-sideband modulator composition is available in LuaRadio as the
[`SSBModulator`]({% base %}/docs/reference-manual.html#ssbmodulator) block.

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_wavfile_ssb_modulator.png" />
</p>

##### Source

``` lua
{% include examples/wavfile_ssb_modulator.lua %}```

##### Usage

```
Usage: examples/wavfile_ssb_modulator.lua <WAV file in> <IQ f32le file out> <bandwidth> <sideband>
```

##### Usage Example

Modulate `test.wav` into `test.iq`, with 3 kHz bandwidth and lower sideband:

```
$ ./luaradio examples/wavfile_ssb_modulator.lua test.wav test.iq 3e3 lsb
```
