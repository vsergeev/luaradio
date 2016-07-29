---
layout: default
title: SSB Receiver Example
---

# [`rtlsdr_ssb.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_ssb.lua)

This example is a
[Single-Sideband](https://en.wikipedia.org/wiki/Single-sideband_modulation)
(SSB) AM radio receiver. SSB is commonly used by amateur radio operators on the
HF band, and sometimes on the VHF and UHF bands, for voice and digital
(modulated in the audio) communication. This example uses the RTL-SDR as an SDR
source, plays audio with PulseAudio, and shows two real-time plots: the RF
spectrum and the demodulated audio spectrum.

This example requires an RF upconverter to listen to stations on the HF and MF
bands with the RTL-SDR.

This single-sideband demodulator composition is available in LuaRadio as the
[`SSBDemodulator`]({% base %}/docs/reference-manual.html#ssbdemodulator) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_ssb.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_ssb.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/d9hjdi657t5i64cmonfhafnh5" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_ssb.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_ssb.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_ssb.lua %}```

##### Usage

```
Usage: examples/rtlsdr_ssb.lua <frequency> <sideband>
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `ssb.wav`.

##### Usage Example

Listen to 3.745 MHz (with a 125 MHz upconverter), lower sideband:

```
$ ./luaradio examples/rtlsdr_ssb.lua 128.745e6 lsb
```
