---
layout: default
title: AM Receiver (Envelope) Example
---

# [`rtlsdr_am_envelope.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_am_envelope.lua)

This example is an AM radio receiver, implemented with an envelope detector. It
can be used to listen to broadcast stations on the MF ([AM
Broadcast](https://en.wikipedia.org/wiki/AM_broadcasting)) and HF ([Shortwave
Broadcast](https://en.wikipedia.org/wiki/Shortwave_radio#Shortwave_broadcasting))
bands, as well as aviation communication on the VHF
[airband](https://en.wikipedia.org/wiki/Airband). It uses the RTL-SDR as an SDR
source, plays audio with PulseAudio, and shows two real-time plots: the RF
spectrum and the demodulated audio spectrum.

This example requires an RF upconverter to listen to stations on the HF and MF
bands with the RTL-SDR.

This AM envelope demodulator composition is available in LuaRadio as the
[`AMEnvelopeDemodulator`]({% base
%}/docs/reference-manual.html#amenvelopedemodulator) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_am_envelope.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_am_envelope.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/d12ff1g9xzs70f3bt80pmm1qn" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_am_envelope.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_am_envelope.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_am_envelope.lua %}```

##### Usage

```
Usage: examples/rtlsdr_am_envelope.lua <frequency>
```

Running this example in a headless environment will inhibit plotting and record
audio to the WAV file `am_envelope.wav`.

##### Usage Example

Listen to [WWV](https://en.wikipedia.org/wiki/WWV_(radio_station)) at 5 MHz
(with a 125 MHz upconverter):

```
$ ./luaradio examples/rtlsdr_am_envelope.lua 130e6
```

Listen to an AM radio station at 560 kHz (with a 125 MHz upconverter):

```
$ ./luaradio examples/rtlsdr_am_envelope.lua 125.560e6
```
