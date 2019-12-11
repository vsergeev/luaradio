---
layout: default
title: IQ File Converter Example
---

# [`iqfile_converter.lua`]({{ site.data.theme.github_url }}/blob/master/examples/iqfile_converter.lua)

This example is an IQ file format converter. It converts the binary encoding of
IQ files from one format, e.g. signed 8-bit, to another, e.g. 32-bit float
little endian. This example doesn't use the RTL-SDR at all, but instead
demonstrates how you can build file-based command-line utilities with
modulation, demodulation, decoding, file conversion, etc. flow graphs that run
to completion.

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_iqfile_converter.png" />
</p>

##### Source

``` lua
{% include examples/iqfile_converter.lua %}```

##### Usage

```
Usage: examples/iqfile_converter.lua <input IQ file> <input format> <output IQ file> <output format>

Supported formats:
    s8, u8,
    u16le, u16be, s16le, s16be,
    u32le, u32be, s32le, s32be,
    f32le, f32be, f64le, f64be
```

##### Usage Example

Convert `test.s8.iq`, with signed 8-bit samples, into `test.f32le.iq`, with
32-bit float little endian samples:

```
$ ./luaradio examples/iqfile_converter.lua test.s8.iq s8 test.f32le.iq f32le
$ du -b test.s8.iq
10236   test.s8.iq
$ du -b test.f32le.iq
40944   test.f32le.iq
$
```
