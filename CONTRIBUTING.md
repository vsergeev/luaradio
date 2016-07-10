# Contributing to LuaRadio

All contributions, big or small, issue or pull request, are welcome and
appreciated.

## Issues

Reports of bugs, installation problems, and other issues are greatly
appreciated. If the issue is related to the codebase, please include the
platform (`luaradio --platform`) and version (`luaradio --version`) of
LuaRadio.

Block and feature requests are also welcome. Please search existing issues and
the [project
roadmap](https://github.com/vsergeev/luaradio/wiki#project-roadmap) to check if
your block or feature has already been requested. If it does exist, feel free
to thumbs up the issue to voice your interest.

Note that your issue title may be reworded, for consistency and tracking.
This is nothing personal, just OCD.

## Want to help?

Check out the
[outstanding](https://github.com/vsergeev/luaradio/wiki#outstanding) features
and bugs of the [project
roadmap](https://github.com/vsergeev/luaradio/wiki#project-roadmap) for
tasks to work on.

## Pull Requests

Pull requests are always welcome.

### Testing

[Travis CI](https://travis-ci.org/vsergeev/luaradio) will run all pull requests
through the unit tests, but it's a good idea to run them locally first.  See
the [tests](tests/) folder for instructions on running the unit tests locally.

### Git History

LuaRadio follows a rebase development flow to maintain a linear history. The
`master` branch is sacrosanct, and will never be rewritten. On the other hand,
the `devel` branch will be frequently amended and reordered.

Your pull requests will cherry-picked, rather than merged, and may be
reshuffled in history before release. GitHub may not like this, but I find the
history much more useful.

### Commit Messages

LuaRadio commit messages adhere to the following format:

```
<component>: <present-tense verb> <what changed>

<additional description, if necessary>
```

The first line should be under 80 characters.

For an example of a typical commit message:

```
blocks/sources/rtlsdr: add device index option
```

Note that your commit message may be reworded for consistency. Again, this is
nothing personal.

## Submitting a Block

Block additions to LuaRadio have a few requirements for consistency, quality
assurance, and minimized dependencies:

* **Naming:** Processing blocks must be suffixed with `Block`, source blocks
  must be suffixed with `Source`, and sink blocks must be suffixed with `Sink`.
  Composite blocks have more flexible naming, but should follow a naming
  precedent if it exists (see the [composites](radio/composites) folder).

* **Testing:** Blocks must be accompanied with a unit test, if possible.
  Signal processing blocks typically include a Python 3 unit test code
  generator.  Python unit test code generators may use
  [numpy](http://www.numpy.org/) and [scipy](https://www.scipy.org/). Composite
  blocks currently do not require a unit test. See the [tests](tests/) folder
  for more details and examples.

* **Dependencies:** Processing blocks may use library acceleration, but must
  also provide a fallback Lua implementation to ensure LuaRadio can be run in a
  non-real-time mode with no external dependencies.

For an example of a typical block addition to LuaRadio:

```
commit d8d2439111cc0596d24836807df872cf6ed38044
Author: Vanya Sergeev <vsergeev@gmail.com>
Date:   Wed Jun 29 03:01:23 2016 -0700

    blocks/signal/manchesterdecoder: add ManchesterDecoderBlock

 radio/blocks/init.lua                                  |  1 +
 radio/blocks/signal/manchesterdecoder.lua              | 63 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/blocks/signal/manchesterdecoder_spec.lua         | 29 +++++++++++++++++++++++++++++
 tests/generate/blocks/signal/manchesterdecoder_spec.py | 28 ++++++++++++++++++++++++++++
 4 files changed, 121 insertions(+)
```

File breakdown:

* `radio/blocks/signal/manchesterdecoder.lua`: Block implementation
* `radio/blocks/init.lua`: Exportation to blocks namespace
* `tests/generate/blocks/signal/manchesterdecoder_spec.py`: Unit test code generator (Python 3)
* `tests/blocks/signal/manchesterdecoder_spec.lua`: Code generated unit test (Lua)

