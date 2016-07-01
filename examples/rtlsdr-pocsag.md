---
layout: default
title: POCSAG Receiver Example
---

# [`rtlsdr_pocsag.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_pocsag.lua)

This example is a [POCSAG](https://en.wikipedia.org/wiki/POCSAG) receiver. It
can be used to receive pager messages dispatched by hospital, fire, emergency,
and police services, as well as some businesses. POCSAG messages are
transmitted in plaintext. It uses the RTL-SDR as an SDR source, writes decoded
POCSAG messages in JSON to standard out, and shows two real-time plots: the RF
spectrum and the demodulated bitstream.

This POCSAG receiver composition is available in LuaRadio as the
[`POCSAGReceiver`]({% base %}/docs/reference-manual.html#pocsagreceiver) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_pocsag.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_pocsag.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/7ucxffe5faew4k522rokw8ydx" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_pocsag.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_pocsag.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_pocsag.lua %}```

##### Usage

```
Usage: examples/rtlsdr_pocsag.lua <frequency>
```

Running this example in a headless environment will inhibit plotting.

You may need to explore your local spectrum with a waterfall receiver to find a
POCSAG transmitter.

##### Usage Example

Receive POCSAG on 152.240 MHz:

```
$ ./luaradio examples/rtlsdr_pocsag.lua 152.240e6
{"address":1234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1973"}
{"address":234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1973"}
{"address":1234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1974"}
{"address":234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1974"}
{"address":1234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1975"}
{"address":234567,"func":2,"alphanumeric":"THIS IS A TEST PERIODIC PAGE SEQUENTIAL NUMBER  1975"}
...
```
