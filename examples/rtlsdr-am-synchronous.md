---
layout: default
title: AM Receiver (Synchronous) Example
---

# [`rtlsdr_am_synchronous.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_am_synchronous.lua)

This example is an AM radio receiver, implemented with a phase-locked loop for
synchronous demodulation. It can be used to listen to broadcast stations on the
MF ([AM Broadcast](https://en.wikipedia.org/wiki/AM_broadcasting)) and HF
([Shortwave
Broadcast](https://en.wikipedia.org/wiki/Shortwave_radio#Shortwave_broadcasting))
bands, as well as aviation communication on the VHF
[airband](https://en.wikipedia.org/wiki/Airband). It uses the RTL-SDR as an SDR
source, plays audio with PulseAudio, and shows two real-time plots: the RF
spectrum and the demodulated audio spectrum.

This example requires an RF upconverter to listen to stations on the HF and MF
bands with the RTL-SDR.

This AM synchronous demodulator composition is available in LuaRadio as the
[`AMSynchronousDemodulator`]({% base
%}/docs/reference-manual.html#amsynchronousdemodulator) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_am_synchronous.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_am_synchronous.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/8hyfpx0bis5ufmbh95ic1cx4o" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_am_synchronous.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_am_synchronous.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_am_synchronous.lua %}```

##### Usage

```
Usage: examples/rtlsdr_am_synchronous.lua <frequency> [audio gain]
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `am_synchronous.wav`.

This example currently uses a constant audio gain block, which may need
adjustment with the station signal strength. In the future, this will be
replaced with an automatic gain control block.

##### Usage Example

Listen to [WWV](https://en.wikipedia.org/wiki/WWV_(radio_station)) at 5 MHz
(with a 125 MHz upconverter), with an audio gain of 40:

```
$ ./luaradio examples/rtlsdr_am_synchronous.lua 130e6 40
```

Listen to an AM radio station at 560 kHz (with a 125 MHz upconverter), with an
audio gain of 40:

```
$ ./luaradio examples/rtlsdr_am_synchronous.lua 125.560e6 40
```
