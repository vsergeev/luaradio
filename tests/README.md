# Testing

LuaRadio unit tests are run with [busted](http://olivinelabs.com/busted/).

Install `busted` with [LuaRocks](https://luarocks.org/):

```
sudo luarocks --lua-version=5.1 install busted
```

Run unit tests:

```
busted
```

## Disabling Libraries

The unit tests can be run with various combinations of external libraries
disabled, controlled by several environment variable flags. See the [Reference
Manual](../docs/0.reference-manual.md#environment-variables) for more
information.

For example, to run all unit tests with only pure Lua implementations and no
external libraries:

```
LUARADIO_DISABLE_VOLK=1 LUARADIO_DISABLE_LIQUID=1 LUARADIO_DISABLE_FFTW3F=1 busted
```

## Code Generation

Most block unit tests are code generated with Python 3, numpy, and scipy. The
Python unit test code generators exist alongside the generated files: e.g.
`blocks/signal/firfilter_spec.py` and `blocks/signal/firfilter_spec.gen.lua`.

The code generated unit tests can be regenerated with `generate.py`:

```
python3 generate.py
```
