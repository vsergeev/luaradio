---
layout: default
title: WBFM Broadcast Stereo Receiver Example
---

# [`rtlsdr_wbfm_stereo.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_wbfm_stereo.lua)

This example is a stereo Wideband FM broadcast radio receiver. It can be used
to listen to [FM Broadcast](https://en.wikipedia.org/wiki/FM_broadcasting)
stations, like the mono Wideband FM example, but it also supports stereo sound.
It uses the RTL-SDR as an SDR source, plays audio with PulseAudio, and shows
three real-time plots: the demodulated FM spectrum, the L+R channel audio
spectrum, and the L-R channel audio spectrum.

This stereo Wideband FM broadcast demodulator composition is available in
LuaRadio as the [`WBFMStereoDemodulator`]({% base
%}/docs/reference-manual.html#wbfmstereodemodulator) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_wbfm_stereo.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_wbfm_stereo.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/3u9w5uve8vlqm7t3nws4nj886" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_wbfm_stereo.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_wbfm_stereo.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_wbfm_stereo.lua %}```

##### Usage

```
Usage: examples/rtlsdr_wbfm_stereo.lua <FM radio frequency>
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `wbfm_stereo.wav`.

##### Usage Example

Listen to 91.1 MHz:

```
$ ./luaradio examples/rtlsdr_wbfm_stereo.lua 91.1e6
```
