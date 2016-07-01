---
layout: default
title: NBFM Receiver Example
---

# [`rtlsdr_nbfm.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_nbfm.lua)

This example is a Narrowband FM radio receiver. It can be used to listen to
[NOAA weather radio](https://en.wikipedia.org/wiki/NOAA_Weather_Radio) in the
US, amateur radio operators, analog police and emergency services, and more, on
the VHF and UHF bands. It uses the RTL-SDR as an SDR source, plays audio with
PulseAudio, and shows two real-time plots: the RF spectrum and the demodulated
audio spectrum.

This NBFM demodulator composition is available in LuaRadio as the
[`NBFMDemodulator`]({% base %}/docs/reference-manual.html#nbfmdemodulator)
block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_nbfm.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_nbfm.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/egmnxazha3rb7r21y0lk9dchv" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_nbfm.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_nbfm.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_nbfm.lua %}```

##### Usage

```
Usage: examples/rtlsdr_nbfm.lua <frequency>
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `nbfm.wav`.

##### Usage Example

Listen to NOAA1, 162.400 MHz:

```
$ ./luaradio examples/rtlsdr_nbfm.lua 162.400e6
```

Additional NOAA weather radio station frequencies: `162.400 MHz` (NOAA1),
`162.425 MHz` (NOAA2), `162.450 MHz` (NOAA3), `162.475 MHz` (NOAA4),
`162.500 MHz` (NOAA5), `162.525 MHz` (NOAA6), `162.550 MHz` (NOAA7).
