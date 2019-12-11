---
layout: default
title: WBFM Broadcast Mono Receiver Example
---

# [`rtlsdr_wbfm_mono.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_wbfm_mono.lua)

This example is a mono Wideband FM broadcast radio receiver. It can be used to
listen to [FM Broadcast](https://en.wikipedia.org/wiki/FM_broadcasting)
stations. It uses the RTL-SDR as an SDR source, plays audio with PulseAudio,
and shows two real-time plots: the demodulated FM spectrum and the L+R channel
audio spectrum.

This mono Wideband FM broadcast demodulator composition is available in
LuaRadio as the [`WBFMMonoDemodulator`]({% base
%}/docs/reference-manual.html#wbfmmonodemodulator) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_wbfm_mono.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_wbfm_mono.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/5ak61ljnvvyh373yra0ohhq3o" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_wbfm_mono.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_wbfm_mono.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_wbfm_mono.lua %}```

##### Usage

```
Usage: examples/rtlsdr_wbfm_mono.lua <FM radio frequency>
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `wbfm_mono.wav`.

##### Usage Example

Listen to 91.1 MHz:

```
$ ./luaradio examples/rtlsdr_wbfm_mono.lua 91.1e6
```
