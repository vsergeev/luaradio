---
layout: default
title: RDS Receiver Example
---

# [`rtlsdr_rds.lua`]({{ site.data.theme.github_url }}/blob/master/examples/rtlsdr_rds.lua)

This example is a [Radio Data
System](https://en.wikipedia.org/wiki/Radio_Data_System) (RDS) receiver. RDS is
a digital protocol used by [FM
Broadcast](https://en.wikipedia.org/wiki/FM_broadcasting) radio stations to
transmit metadata about the station and its programming. This protocol is most
commonly known for providing station and song text information with "RadioText"
messages.  This examples uses the RTL-SDR as an SDR source, writes decoded RDS
frames in JSON to standard out, and shows three real-time plots: the
demodulated FM spectrum, the BPSK spectrum, and the BPSK constellation.

This example can be used with FM Broadcast radio stations, like the [WBFM
Mono](rtlsdr-wbfm-mono.html) and [WBFM Stereo](rtlsdr-wbfm-stereo.html)
examples, but may require a decent antenna or a strong station.

This RDS receiver composition is available in LuaRadio as the
[`RDSReceiver`]({% base %}/docs/reference-manual.html#rdsreceiver) block.

<p align="center">
<a href="{% base %}/images/screenshot-rtlsdr_rds.png" target="_blank"><img src="{% base %}{% thumbnail /images/screenshot-rtlsdr_rds.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
<a href="https://asciinema.org/a/a28zfvwaxdz0s4yc8e0wg1ky7" target="_blank"><img src="{% base %}{% thumbnail /images/asciinema-rtlsdr_rds.png 395 %}" style="display: inline-block; vertical-align: middle;" /></a>
</p>

##### Flow Graph

<p align="center">
<img src="{% base %}/docs/figures/flowgraph_rtlsdr_rds.png" />
</p>

##### Source

``` lua
{% include examples/rtlsdr_rds.lua %}```

##### Usage

```
Usage: examples/rtlsdr_rds.lua <FM radio frequency>
```

Running this example in a headless environment will inhibit plotting.

##### Usage Example

Receive RDS on 88.5 MHz:

```
$ ./luaradio examples/rtlsdr_rds.lua 88.5e6
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":0,"text_address":3,"ms_code":1,"di_value":1,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":2,"group_version":0,"pty_code":22},"data":{"type":"radiotext","text_data":"Nort","text_address":6,"ab_flag":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"KQ","di_position":3,"text_address":0,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":2,"group_version":0,"pty_code":22},"data":{"type":"radiotext","text_data":"hern","text_address":7,"ab_flag":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"ED","di_position":2,"text_address":1,"ms_code":1,"di_value":0,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":1,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,4805,160,2002]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":1,"text_address":2,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,24158,16374]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":0,"text_address":3,"ms_code":1,"di_value":1,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":2,"group_version":0,"pty_code":22},"data":{"type":"radiotext","text_data":" Cal","text_address":8,"ab_flag":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,24158,16374]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"KQ","di_position":3,"text_address":0,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":3,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,13008,16833,52550]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"ED","di_position":2,"text_address":1,"ms_code":1,"di_value":0,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,24158,16374]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":1,"text_address":2,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":4,"group_version":0,"pty_code":22},"data":{"type":"datetime","time":{"offset":-7,"hour":9,"minute":57},"date":{"day":27,"year":2016,"month":5}}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,28270,16202]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":0,"text_address":3,"ms_code":1,"di_value":1,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":2,"group_version":0,"pty_code":22},"data":{"type":"radiotext","text_data":"ifor","text_address":9,"ab_flag":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"KQ","di_position":3,"text_address":0,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,28270,16202]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"ED","di_position":2,"text_address":1,"ms_code":1,"di_value":0,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":1,"text_address":2,"ms_code":1,"di_value":0,"af_code":[227,10],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":8,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,33494,28270,16202]}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":0,"group_version":0,"pty_code":22},"data":{"text_data":"  ","di_position":0,"text_address":3,"ms_code":1,"di_value":1,"af_code":[6,8],"type":"basictuning","ta_code":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":2,"group_version":0,"pty_code":22},"data":{"type":"radiotext","text_data":"nia ","text_address":10,"ab_flag":0}}
{"header":{"pi_code":15019,"tp_code":0,"group_code":1,"group_version":0,"pty_code":22},"data":{"type":"raw","frame":[15019,4806,160,2002]}}
...
```
