# Embedding LuaRadio

The entirety of the LuaRadio framework and the LuaJIT interpreter can be
packaged into a single library that exports a simple C API. The API can be used
to create a LuaRadio context, load a LuaRadio script with a top-level flow
graph, and control the top-level flow graph (start, status, wait, stop). This
library, `libluaradio`, can then be dynamically or statically linked into an
application to add dedicated or scriptable signal processing engine.

The [fm-radio](examples/fm-radio.c) example is a standalone command-line FM
broadcast radio receiver. The [rds-timesync](examples/rds-timesync.c) is a
standalone command-line tool that syncs the system time and date with an
RDS-enabled FM radio station.

See the [Embedding LuaRadio](../docs/4.embedding-luaradio.md) documentation for
more information.

## Building

Build `libluaradio`, unit tests, and examples with:

```
make
```

Run unit tests with:

```
make runtests
```

## File Structure

* [Makefile](Makefile) - C library Makefile
* [luaradio.c](luaradio.c) - C API implementation
* [luaradio.h](luaradio.h) - C API header
* [examples/](examples) - C API examples
* [tests/](tests) - C API unit tests
