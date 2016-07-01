---
layout: default
title: AX.25 Packet Radio Receiver Example
---

# [`rtlsdr_ax25.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_ax25.lua)

This example is an [AX.25](https://en.wikipedia.org/wiki/AX.25) packet radio
receiver for Narrowband FM, Bell 202 AFSK modulated transmissions on the VHF
and UHF bands. It can be used to receive
[APRS](https://en.wikipedia.org/wiki/Automatic_Packet_Reporting_System) and
other AX.25-based data transmissions. It uses the RTL-SDR as an SDR source,
writes decoded AX.25 frames in JSON to standard out, and shows two real-time
plots: the RF spectrum and the demodulated bitstream.

This AX.25 receiver composition is available in LuaRadio as the
[`AX25Receiver`]({% base %}/docs/reference-manual.html#ax25receiver) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_ax25.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_ax25.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/3cv1a3tjkcqdtgkkwgqo37lha" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_ax25.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_ax25.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_ax25.lua %}```

##### Usage

```
Usage: examples/rtlsdr_ax25.lua <frequency>
```

Running this example in a headless environment will inhibit plotting.

##### Usage Example

Receive APRS on 144.390 MHz, the North American VHF APRS frequency:

```
$ ./luaradio examples/rtlsdr_ax25.lua 144.390e6
{"payload":"@030151z3845.28N/12035.52W_000/000g000t054r000p000P000h70b10136/ {UIV32N}\r","control":3,"addresses":[{"ssid":48,"callsign":"APU25N"},{"ssid":112,"callsign":"K6GER "},{"ssid":112,"callsign":"WARD  "},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE2 "}],"pid":240}
{"payload":"`2-1l 5k/'\"3r}GTARC 146.805 & 406.600 both (-) PL 100|)2%n']|!w?;!|3","control":3,"addresses":[{"ssid":48,"callsign":"S8QXXW"},{"ssid":57,"callsign":"KJ6PCW"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "},{"ssid":49,"callsign":"WIDE2 "}],"pid":240}
{"payload":"`2-1l 5k/'\"3r}GTARC 146.805 & 406.600 both (-) PL 100|)2%n']|!w?;!|3","control":3,"addresses":[{"ssid":48,"callsign":"S8QXXW"},{"ssid":57,"callsign":"KJ6PCW"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "},{"ssid":112,"callsign":"BKELEY"},{"ssid":112,"callsign":"WIDE2 "}],"pid":240}
{"payload":"@094656h3754.16NI12216.92W&(Time 0:00:00)PHG3340/Kensington, CA (I-GATE) */A=000404","control":3,"addresses":[{"ssid":112,"callsign":"APWW10"},{"ssid":53,"callsign":"KC6SSM"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "},{"ssid":49,"callsign":"WIDE2 "}],"pid":240}
{"payload":"!3956.16N/12138.86W# 13.6V 62F ","control":3,"addresses":[{"ssid":112,"callsign":"APOT30"},{"ssid":115,"callsign":"W6SCR "},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "}],"pid":240}
{"payload":"`1N8l#K>/`\"4{}443.575MHz T110 +500_%\r","control":3,"addresses":[{"ssid":48,"callsign":"SWRSYY"},{"ssid":121,"callsign":"KE6STH"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "},{"ssid":49,"callsign":"WIDE2 "}],"pid":240}
{"payload":"`1N8l#K>/`\"4{}443.575MHz T110 +500_%\r","control":3,"addresses":[{"ssid":48,"callsign":"SWRSYY"},{"ssid":121,"callsign":"KE6STH"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE1 "},{"ssid":112,"callsign":"BKELEY"},{"ssid":112,"callsign":"WIDE2 "}],"pid":240}
{"payload":"@270947z3715.26N/12153.30W#Digi & Igate / ron@k6rpt.com","control":3,"addresses":[{"ssid":48,"callsign":"APMI06"},{"ssid":48,"callsign":"K6RPT "},{"ssid":115,"callsign":"N6ZX  "},{"ssid":49,"callsign":"WIDE2 "}],"pid":240}
{"payload":"@270947z3715.26N/12153.30W#Digi & Igate / ron@k6rpt.com","control":3,"addresses":[{"ssid":48,"callsign":"APMI06"},{"ssid":48,"callsign":"K6RPT "},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"BKELEY"},{"ssid":112,"callsign":"WIDE2 "}],"pid":240}
{"payload":"!4001.07N/12122.89W# 12.8V 44F K6FHL Highlakes Fillin W1","control":3,"addresses":[{"ssid":112,"callsign":"APOT30"},{"ssid":112,"callsign":"HILAKE"},{"ssid":115,"callsign":"N6ZX  "},{"ssid":112,"callsign":"WIDE2 "}],"pid":240}
...
```
