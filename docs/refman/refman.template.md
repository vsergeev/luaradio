<%namespace file="refman.template.utils.mako" name="utils" />\
# LuaRadio Reference Manual

Generated from LuaRadio `${utils.attr.git_version}`.

% if not utils.attr.disable_toc:
## Table of contents

* [Example](#example)
* [Running](#running)
    * [`luaradio` runner](#luaradio-runner)
    * [Environment Variables](#environment-variables)
* [Blocks](#blocks)
    * [Composition](#composition)
        * [CompositeBlock](#compositeblock)
% for category in utils.attr.block_categories:
    * [${category}](#${category.replace(" ", "-").lower()})
%   for block in blocks[category]:
        * [${block.name}](#${block.name.lower()})
%     for child in block.children:
        * [${child.name}](#${child.name.replace(".", "").lower()})
%     endfor
%   endfor
% endfor
* [Infrastructure](#infrastructure)
    * [Package](#package)
    * [Basic Types](#basic-types)
        * [ComplexFloat32](#complexfloat32)
        * [Float32](#float32)
        * [Bit](#bit)
        * [Byte](#byte)
    * [Type Factories](#type-factories)
        * [CStructType](#cstructtype)
        * [ObjectType](#objecttype)
    * [Vector](#vector)
        * [Vector](#vector-1)
        * [ObjectVector](#objectvector)
    * [Block](#block)
        * [Input](#input)
        * [Output](#output)
        * [Block](#block-1)
    * [Debug](#debug)
    * [Platform](#platform)

% endif
## Example

<p align="center">
<img src="figures/flowgraph_rtlsdr_wbfm_stereo_composite.png" />
</p>


``` lua
local radio = require('radio')

-- RTL-SDR Source, frequency 88.5 MHz - 250 kHz, sample rate 1102500 Hz
local source = radio.RtlSdrSource(88.5e6 - 250e3, 1102500)
-- Tuner block, translate -250 kHz, filter 200 kHz, decimate by 5
local tuner = radio.TunerBlock(-250e3, 200e3, 5)
-- Wideband FM Stereo Demodulator block
local demodulator = radio.WBFMStereoDemodulator()
-- Left and right AF downsampler blocks
local l_downsampler = radio.DownsamplerBlock(5)
local r_downsampler = radio.DownsamplerBlock(5)
-- Audio sink, 2 channels for left and right audio
local sink = radio.PulseAudioSink(2)
-- Top-level block
local top = radio.CompositeBlock()

-- Connect blocks in top block
top:connect(source, tuner, demodulator)
top:connect(demodulator, 'left', l_downsampler, 'in')
top:connect(demodulator, 'right', r_downsampler, 'in')
top:connect(l_downsampler, 'out', sink, 'in1')
top:connect(r_downsampler, 'out', sink, 'in2')

-- Run top block
top:run()
```

```
$ luaradio example.lua
```

## Running

LuaRadio scripts can be run with the `luaradio` runner, or directly with
`luajit`, if the `radio` package is installed in your Lua path.

### `luaradio` runner

The `luaradio` runner is a simple wrapper script for running LuaRadio scripts.
It can also print version information, dump relevant platform information, and
adjust the runtime debug verbosity of scripts. The runner modifies the Lua path
to support importing the `radio` package locally, so it can be used to run
LuaRadio scripts directly from the repository without installation.

```
$ ./luaradio
Usage: luaradio [options] <script> [args]

Options:
   -h, --help      Print help and exit
   --version       Print version and exit
   --platform      Dump platform and exit
   -v, --verbose   Enable debug verbosity
$
```

To run a script, use `luaradio` as you would use `luajit`:

```
$ luaradio script.lua
```

To run a script with debug verbosity:

```
$ luaradio -v script.lua
```

### Environment Variables

LuaRadio interprets several environment variables to adjust runtime settings.
These environment variables are treated as flags that can be enabled with value
`1` (or values `y`, `yes`, `true`).

* `LUARADIO_DEBUG` - Enable debug verbosity
* `LUARADIO_DISABLE_LIQUID` - Disable liquid-dsp library
* `LUARADIO_DISABLE_VOLK` - Disable volk library
* `LUARADIO_DISABLE_FFTW3F` - Disable fftw3f library

For example, to enable debug verbosity:

```
$ LUARADIO_DEBUG=1 luaradio script.lua
```

To disable use of the VOLK library:

```
$ LUARADIO_DISABLE_VOLK=1 luaradio script.lua
```

To run a script with no external libraries for acceleration:

```
$ LUARADIO_DISABLE_LIQUID=1 LUARADIO_DISABLE_VOLK=1 LUARADIO_DISABLE_FFTW3F=1 luaradio script.lua
```

## Blocks

### Composition

${utils.render(modules['radio.core.composite'].children[0], namespace="radio.")}
% for category in utils.attr.block_categories:

### ${category}

%   for block in blocks[category]:
${utils.render(block, namespace="radio.")}
%   endfor
% endfor

## Infrastructure

### Package

${utils.render(modules['radio'])}

### Basic Types

${utils.render(datatypes['ComplexFloat32'], namespace="radio.types.")}
${utils.render(datatypes['Float32'], namespace="radio.types.")}
${utils.render(datatypes['Bit'], namespace="radio.types.")}
${utils.render(datatypes['Byte'], namespace="radio.types.")}

### Type Factories

${utils.render(datatypes['CStructType'], namespace="radio.types.")}
${utils.render(datatypes['ObjectType'], namespace="radio.types.")}

### Vector

${utils.render(modules['radio.vector'])}

### Block

${utils.render(modules['radio.block'])}

### Debug

${utils.render(modules['radio.debug'])}

### Platform

${utils.render(modules['radio.platform'])}
