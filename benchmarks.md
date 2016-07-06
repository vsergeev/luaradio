---
layout: default
title: Benchmarks
chartjs: true
---

# Benchmarks

These benchmarks are real-time throughput measurements of blocks, measured in
samples per second, under both LuaRadio and GNU Radio. Equivalent blocks from
LuaRadio and GNU Radio are compared, and the results are normalized to GNU
Radio performance. Benchmark results are included for two platforms: an Intel
i5 desktop and the Raspberry Pi 3. The benchmark suites can be found in the
[`benchmarks/`](https://github.com/vsergeev/luaradio/tree/master/benchmarks)
folder of the project.

#### Observations

Generally speaking, LuaRadio performance is on the same order as GNU Radio
performance. In computationally expensive blocks, like filters, LuaRadio has
matching or slightly better performance to GNU Radio. In other cases, LuaRadio
has 30% to 80% the performance of GNU Radio, but this is typically for blocks
that are already in the very high throughput territory, e.g. hundreds to
thousands of megasamples per second on an Intel i5 desktop. Analogous
observations hold for the Raspberry Pi 3.

Some blocks in LuaRadio, like the `SignalSource`, have not yet been optimized
with library accelerated implementations. These blocks will see more comparable
throughput results to GNU Radio with future performance improvements.

#### Caveats

These benchmarks are implemented by measuring the number of samples produced by
the entire benchmark flow graph over a duration of time. The resulting
throughput includes the overhead of the source blocks, as well as the
framework's overhead of serializing samples between blocks. However, the block
under test is the limiting factor by several orders of magnitude (see
benchmarks of the sources alone for validation of this), so the throughput of
the benchmark flow graph corresponds roughly to the throughput of the block.

These results do not reflect the performance degradation that occurs after all
available processor cores are utilized in a larger flow graph. Instead, these
benchmarks represent a block's approximate throughput on a platform, if one CPU
core were dedicated entirely to it. Nonetheless, the benchmarks still give a
good idea of whether or not a block will present a real-time bottleneck to a
flow graph with a certain upstream sample rate.

The benchmarks are sensitive to CPU load by external processes, and are
specific to the platform. Your actual results may vary, but the overall
performance relationship between LuaRadio and GNU Radio should remain similar.

#### Intel i5 Desktop

{% benchmarks_info i5 %}

<canvas id="i5_benchmarks" width="100%" height="300"></canvas>
<script>
{% benchmarks i5_benchmarks i5 "i5 Desktop" %}
</script>

#### Raspberry Pi 3

{% benchmarks_info rpi3 %}

<canvas id="rpi3_benchmarks" width="100%" height="300"></canvas>
<script>
{% benchmarks rpi3_benchmarks rpi3 "Raspberry Pi 3" %}
</script>

<br/>
