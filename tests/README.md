# Testing

LuaRadio unit tests are run with [busted](http://olivinelabs.com/busted/):

```
busted --lua=luajit --lpath="./?/init.lua" --no-auto-insulate tests/
```

The unit tests can be run with various combinations of external libraries
disabled, controlled by several environment variables. See the [Reference
Manual](../docs/0.reference_manual.md#environment-variables) for more
information.

For example, to run all unit tests with only pure Lua implementations and no
external libraries:

```
LUARADIO_DISABLE_VOLK=1 LUARADIO_DISABLE_LIQUID=1 LUARADIO_DISABLE_FFTW3F=1 \
busted --lua=luajit --lpath="./?/init.lua" --no-auto-insulate tests/
```

Many block unit tests are code generated with Python 3. The Python unit test
code generators are available in the [generate](generate/) folder.

The code generated unit tests can be regenerated `tests/generate/generate.py`:

```
python3 tests/generate/generate.py
```
