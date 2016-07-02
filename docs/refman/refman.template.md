{%

local git_version = io.popen("git describe --abbrev --always --tags"):read()

local block_categories = {"Sources", "Sinks", "Filtering", "Math Operations", "Sample Rate Manipulation", "Spectrum Manipulation", "Carrier and Clock Recovery", "Digital", "Type Conversion", "Miscellaneous", "Modulation", "Demodulation", "Protocol", "Receivers"}

local block_macro = [[
{% if os.getenv("REFMAN_DIVS") then %}
<div class="block">
{% end %]]..[[}
#### {*block.name*}

{* block.description *}

##### `radio.{*block.name*}({*block.args_string*})`

{% if #block.args > 0 then %]]..[[}
###### Arguments

{% for _, arg in ipairs(block.args) do %]]..[[}
* `{*arg.name*}` (*{* string.gsub(arg.type, "|", "\\|") *}*): {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% end %]]..[[}

{% end %]]..[[}
###### Type Signatures

{% for _, signature in ipairs(block.signatures) do
    local inputs = {}
    for _, input in ipairs(signature.inputs) do
        inputs[#inputs + 1] = string.format("`%s` *%s*", input.name, input.type)
    end
    local outputs = {}
    for _, output in ipairs(signature.outputs) do
        outputs[#outputs + 1] = string.format("`%s` *%s*", output.name, output.type)
    end
    inputs = table.concat(inputs, ", ")
    outputs = table.concat(outputs, ", ")
%]]..[[}
{% if #inputs > 0 and #outputs > 0 then %]]..[[}
* {*inputs*} ➔❑➔ {*outputs*}
{% elseif #inputs == 0 and #outputs > 0 then %]]..[[}
* ❑➔ {*outputs*}
{% elseif #inputs > 0 and #outputs == 0 then %]]..[[}
* {*inputs*} ➔❑
{% end %]]..[[}
{% end %]]..[[}

###### Example

``` lua
{*block.example*}
```
{% if os.getenv("REFMAN_DIVS") then %}
</div>
{% end %]]..[[}
--------------------------------------------------------------------------------
]]

local class_macro = [[
{% if os.getenv("REFMAN_DIVS") then %}
<div class="class">
{% end %]]..[[}
#### {*class.name*}

##### `{*namespace*}{*class.name*}({*class.args_string*})`

{*class.description*}

{% if #class.args > 0 then %]]..[[}
###### Arguments

{% for _, arg in ipairs(class.args) do %]]..[[}
* `{*arg.name*}` (*{* string.gsub(arg.type, "|", "\\|") *}*): {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% end %]]..[[}

{% end %]]..[[}
{% if class.example then %]]..[[}
###### Example

``` lua
{*class.example*}
```

{% end %]]..[[}
{% if #class.methods > 0 then %]]..[[}
{% for _, method in ipairs(class.methods) do %]]..[[}
##### `{*method.name*}({*method.args_string*})`

{* method.desc *}

    {% if #method.args > 0 then %]]..[[}
###### Arguments

{% for _, arg in ipairs(method.args) do %]]..[[}
{% if arg.type then %]]..[[}
* `{*arg.name*}` (*{* string.gsub(arg.type, "|", "\\|") *}*): {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% else %]]..[[}
* `{*arg.name*}`: {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% end %]]..[[}
{% end %]]..[[}

    {% end
    if #method.returns > 0 then %]]..[[}
###### Returns

{% for _, ret in ipairs(method.returns) do %]]..[[}
* {*ret.desc*} (*{*ret.type*}*)
{% end %]]..[[}

    {% end
    if method.raises then %]]..[[}
###### Raises

{% for _, raise in ipairs(method.raises) do %]]..[[}
* {*raise*}
{% end %]]..[[}

    {% end
    if method.example then %]]..[[}
###### Example

``` lua
{*method.example*}
```

{% end %]]..[[}
{% end %]]..[[}
{% end %]]..[[}
{% if os.getenv("REFMAN_DIVS") then %}
</div>
{% end %]]..[[}
--------------------------------------------------------------------------------
]]

local function_macro = [[
{% if os.getenv("REFMAN_DIVS") then %}
<div class="function">
{% end %]]..[[}
##### `{* namespace *}{*func.name*}({*func.args_string*})`

{*func.desc*}

{% if #func.args > 0 then %]]..[[}
###### Arguments

{% for _, arg in ipairs(func.args) do %]]..[[}
{% if arg.type then %]]..[[}
* `{*arg.name*}` (*{* string.gsub(arg.type, "|", "\\|") *}*): {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% else %]]..[[}
* `{*arg.name*}`: {* string.gsub(arg.desc, "%s+%* ", "\n    * ") *}
{% end %]]..[[}
{% end %]]..[[}

{% end
if #func.returns > 0 then %]]..[[}
###### Returns

{% for _, ret in ipairs(func.returns) do %]]..[[}
* {*ret.desc*} (*{*ret.type*}*)
{% end %]]..[[}

{% end
if func.raises then %]]..[[}
###### Raises

{% for _, raise in ipairs(func.raises) do %]]..[[}
* {*raise*}
{% end %]]..[[}

{% end
if func.example then %]]..[[}
###### Example
``` lua
{*func.example*}
```

{% end %]]..[[}
{% if os.getenv("REFMAN_DIVS") then %}
</div>
{% end %]]..[[}
--------------------------------------------------------------------------------
]]

local field_macro = [[
{% if os.getenv("REFMAN_DIVS") then %}
<div class="field">
{% end %]]..[[}
##### `{* namespace *}{* field.name *}`

*{*field.type*}*: {*field.desc*}

{% if os.getenv("REFMAN_DIVS") then %}
</div>
{% end %]]..[[}
--------------------------------------------------------------------------------
]]
%}
# LuaRadio Reference Manual

Generated from LuaRadio `{* git_version *}`.

## Table of contents

* [Example](#example)
* [Running](#running)
    * [`luaradio` runner](#luaradio-runner)
    * [Environment Variables](#environment-variables)
* [Blocks](#blocks)
    * [Composition](#composition)
        * [CompositeBlock](#compositeblock)
{% for _, category in ipairs(block_categories) do %}
    * [{* category *}](#{* string.gsub(string.lower(category), " ", "-") *})
{%  for _, item in ipairs(Blocks[category]) do %}
        * [{* item.info.name *}](#{* string.gsub(string.lower(item.info.name), "%.", "") *})
{%  end
end %}
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
`luajit`, if the `radio` package is in installed in your Lua path.

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

{* template.compile(class_macro){class = Modules['radio.composite'][1].info, namespace = "radio."} *}

{% for _, category in ipairs(block_categories) do %}
### {* category *}

{%  for _, item in ipairs(Blocks[category]) do %}
{% if item.type == "block" then %}
{* template.compile(block_macro){block = item.info} *}
{% elseif item.type == "type" then %}
{* template.compile(class_macro){class = item.info, namespace = "radio."} *}
{% end %}
{% end %}

{% end %}

## Infrastructure

### Package

{* Modules["radio"].description *}

{% for _, item in ipairs(Modules["radio"]) do %}
{* template.compile(field_macro){field = item.info, namespace = "radio."} *}
{% end %}

### Basic Types

{* template.compile(class_macro){class = lookup("radio.types", "class", "ComplexFloat32"), namespace = "radio.types."} *}
{* template.compile(class_macro){class = lookup("radio.types", "class", "Float32"), namespace = "radio.types."} *}
{* template.compile(class_macro){class = lookup("radio.types", "class", "Bit"), namespace = "radio.types."} *}
{* template.compile(class_macro){class = lookup("radio.types", "class", "Byte"), namespace = "radio.types."} *}

### Type Factories

{* template.compile(class_macro){class = lookup("radio.types", "class", "CStructType"), namespace = "radio.types."} *}
{* template.compile(class_macro){class = lookup("radio.types", "class", "ObjectType"), namespace = "radio.types."} *}

### Vector

{* Modules["radio.vector"].description *}

{* template.compile(class_macro){class = lookup("radio.vector", "class", "Vector"), namespace = "radio.vector."} *}
{* template.compile(class_macro){class = lookup("radio.vector", "class", "ObjectVector"), namespace = "radio.vector."} *}

### Block

{* Modules["radio.block"].description *}

{* template.compile(class_macro){class = lookup("radio.block", "class", "Input"), namespace = "radio.block."} *}
{* template.compile(class_macro){class = lookup("radio.block", "class", "Output"), namespace = "radio.block."} *}
{* template.compile(class_macro){class = lookup("radio.block", "class", "Block"), namespace = "radio.block."} *}
{* template.compile(function_macro){func = lookup("radio.block", "function", "factory"), namespace = "radio.block."} *}

### Debug

{* Modules["radio.debug"].description *}

{% for _, item in ipairs(Modules["radio.debug"]) do
if item.type == "field" then %}
{* template.compile(field_macro){field = item.info, namespace = "radio.debug."} *}
{% end
end %}
{% for _, item in ipairs(Modules["radio.debug"]) do
if item.type == "function" then %}
{* template.compile(function_macro){func = item.info, namespace = "radio.debug."} *}
{% end
end %}

### Platform

{* Modules["radio.platform"].description *}

{% for _, item in ipairs(Modules["radio.platform"]) do %}
{* template.compile(field_macro){field = item.info, namespace = "radio.platform."} *}
{% end %}

