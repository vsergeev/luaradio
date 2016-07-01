module Jekyll
  class BenchmarksInfoTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      @platform = params.strip
    end

    require 'json'
    def render(context)
      # Read benchmarks JSON
      luaradio_json = File.read(File.join(Dir.pwd, '_includes', "benchmarks", "benchmarks." + @platform + ".luaradio.json"))
      gnuradio_json = File.read(File.join(Dir.pwd, '_includes', "benchmarks", "benchmarks." + @platform + ".gnuradio.json"))

      # Parse JSON
      luaradio_results = JSON.parse(luaradio_json)
      gnuradio_results = JSON.parse(gnuradio_json)

      # Gather platform information
      platform_info = {
        'luaradio_version' => luaradio_results['version'],
        'gnuradio_version' => gnuradio_results['version'],
        'cpu_count' => luaradio_results['platform']['cpu_count'],
        'cpu_model' => luaradio_results['platform']['cpu_model'],
        'arch' => luaradio_results['platform']['arch'],
        'os' => luaradio_results['platform']['os'],
        'luaradio_features' => luaradio_results['platform']['features'].keys.select{|k| luaradio_results['platform']['features'][k]},
      }

      #content =  "```\n"
      #content += "LuaRadio version      " + platform_info['luaradio_version'] + "\n"
      #content += "GNU Radio version     " + platform_info['gnuradio_version'] + "\n"
      #content += "CPU model             " + platform_info['cpu_model'] + "\n"
      #content += "CPU count             " + platform_info['cpu_count'].to_s + "\n"
      #content += "Architecture          " + platform_info['arch'] + "\n"
      #content += "Operating System      " + platform_info['os'] + "\n"
      #content += "LuaRadio features     " + platform_info['luaradio_features'].join(", ") + "\n"
      #content += "```"

      content =  "<pre class=\"benchmark-platform\">\n"
      content += "<b>LuaRadio version</b>      " + platform_info['luaradio_version'] + "\n"
      content += "<b>GNU Radio version</b>     " + platform_info['gnuradio_version'] + "\n"
      content += "<b>CPU model</b>             " + platform_info['cpu_model'] + "\n"
      content += "<b>CPU count</b>             " + platform_info['cpu_count'].to_s + "\n"
      content += "<b>Architecture</b>          " + platform_info['arch'] + "\n"
      content += "<b>Operating System</b>      " + platform_info['os'] + "\n"
      content += "<b>LuaRadio features</b>     " + platform_info['luaradio_features'].join(", ") + "\n"
      content += "</pre>"

      content
    end
  end

  class BenchmarksTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      params = params.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
      params.map!{|param| param.gsub("\"", "")}
      @div_id = params[0]
      @platform = params[1]
      @title = params[2]
    end

    require 'json'
    def render(context)
      # Read benchmarks JSON
      luaradio_json = File.read(File.join(Dir.pwd, '_includes', "benchmarks", "benchmarks." + @platform + ".luaradio.json"))
      gnuradio_json = File.read(File.join(Dir.pwd, '_includes', "benchmarks", "benchmarks." + @platform + ".gnuradio.json"))

      # Parse JSON
      luaradio_results = JSON.parse(luaradio_json)
      gnuradio_results = JSON.parse(gnuradio_json)

      # Transform results into hash of name to benchmark
      luaradio_benchmarks = Hash[luaradio_results['benchmarks'].collect{ |v| [v['name'], v['results']] }]
      gnuradio_benchmarks = Hash[gnuradio_results['benchmarks'].collect{ |v| [v['name'], v['results']] }]

      def format_name(name)
        if name.include? " (" 
          tokens = name.split(" (")
          return [tokens[0], "(" + tokens[1]]
        end
        return name
      end

      # Gather common tests and compute ratio
      benchmarks = luaradio_benchmarks.keys.select {|k| gnuradio_benchmarks.member?(k) }.map{ |test|
        {
          'name' => format_name(test),
          'ratio' => 100*luaradio_benchmarks[test]['samples_per_second'] / gnuradio_benchmarks[test]['samples_per_second'],
          'luaradio_sps' => luaradio_benchmarks[test]['samples_per_second'],
          'luaradio_sps_stdev' => luaradio_benchmarks[test]['samples_per_second_stdev'],
          'gnuradio_sps' => gnuradio_benchmarks[test]['samples_per_second'],
          'gnuradio_sps_stdev' => gnuradio_benchmarks[test]['samples_per_second_stdev']
        }
      }
      # Sort tests by ratio
      benchmarks.sort_by!{ |benchmark| benchmark['ratio'] }
      benchmarks.reverse!

      highlight_color = context['site']['data']['theme']['highlight_color'][1..-1].to_i(16)
      contrast_color = context['site']['data']['theme']['contrast_color'][1..-1].to_i(16)

      highlight_color = [(highlight_color >> 16) & 0xff, (highlight_color >> 8) & 0xff, highlight_color & 0xff]
      contrast_color = [(contrast_color >> 16) & 0xff, (contrast_color >> 8) & 0xff, contrast_color & 0xff]

      # Arrange data into Chart.js form
      luaradio_dataset = {
        'data' => benchmarks.map{ |benchmark| [benchmark['ratio'], 250].min }, # Hack until Chart.js fixes this FIXME
        'label' => 'LuaRadio',
        'backgroundColor' => "rgba(#{highlight_color[0]}, #{highlight_color[1]}, #{highlight_color[2]}, 0.75)",
      }
      gnuradio_dataset = {
        'data' => benchmarks.map{ |benchmark| 100.0 },
        'label' => 'GNU Radio',
        'backgroundColor' => "rgba(#{contrast_color[0]}, #{contrast_color[1]}, #{contrast_color[2]}, 0.75)",
      }
      data = {
        'labels' => benchmarks.map{ |benchmark| benchmark['name'] },
        'datasets' => [luaradio_dataset, gnuradio_dataset],
      }
      config = {
        'type' => 'horizontalBar',
        'data' => data,
        'options' => {
          'scales' => {
            'xAxes' => [{
              'type' => 'linear',
              'ticks' => {
                'min' => 0,
                'max' => 200,
              },
              'scaleLabel' => {
                'labelString' => 'Percent',
                'display' => true,
              },
              'position' => 'top',
            }],
          },
          'tooltips' => {
            'mode' => 'label',
            'callbacks' => {},
          },
          'legend' => {
            'position' => 'top',
          },
          'isFixedWidth' => false,
        },
      }
      tooltips = [
        benchmarks.map{ |benchmark| sprintf("LuaRadio: %.1f%%, μ %.2f MS/s, σ %.2f MS/s",
                                              benchmark['ratio'],
                                              benchmark['luaradio_sps']/1e6,
                                              benchmark['luaradio_sps_stdev']/1e6) },
        benchmarks.map{ |benchmark| sprintf("GNU Radio: 100.0%%, μ %.2f MS/s, σ %.2f MS/s",
                                              benchmark['gnuradio_sps']/1e6,
                                              benchmark['gnuradio_sps_stdev']/1e6) },
      ]

      script = "var #{@div_id}_data = #{JSON.generate(config)};\n"
      script += "var #{@div_id}_tooltips = #{JSON.generate(tooltips)};\n"
      script += "#{@div_id}_data['options']['tooltips']['callbacks']['label'] = function (tooltipItem, data) { return #{@div_id}_tooltips[tooltipItem['datasetIndex']][tooltipItem['index']] };\n"
      script += "new Chart(document.getElementById(\"#{@div_id}\"), #{@div_id}_data);"

      script
    end
  end
end

Liquid::Template.register_tag('benchmarks_info', Jekyll::BenchmarksInfoTag)
Liquid::Template.register_tag('benchmarks', Jekyll::BenchmarksTag)
