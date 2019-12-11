module Jekyll
  class ThumbnailTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      params = params.split(' ')
      @path = params[0]
      @width = params[1].to_i
    end

    require 'fileutils'
    require 'mini_magick'
    def render(context)
      thumb_path = @path.gsub(/\.(.*)$/, '-thumb.\1')

      in_path = File.join(Dir.pwd, @path)
      if not File.exist?(in_path) then
        in_path = File.join(Dir.pwd, '_includes', @path)
      end

      out_path = File.join('/tmp', '_thumbnails', thumb_path)

      # Create leading directories
      FileUtils.mkpath(File.dirname(out_path))

      # Open and resize image
      image = MiniMagick::Image.open(in_path)
      image.resize(@width.to_s + "x")
      image.write(out_path)

      # Mark it as a static file for copying
      site = context.registers[:site]
      site.static_files << Jekyll::StaticFile.new(site, File.join('/tmp', '_thumbnails'), '', thumb_path)

      return thumb_path
    end
  end

  class ImageTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
      params = params.split(' ')
      @path = params[0]
    end

    def render(context)
      # Mark it as a static file for copying
      site = context.registers[:site]
      site.static_files << Jekyll::StaticFile.new(site, File.join(site.source, '_includes'), '', @path)

      return @path
    end
  end

end

Liquid::Template.register_tag('thumbnail', Jekyll::ThumbnailTag)
Liquid::Template.register_tag('image', Jekyll::ImageTag)
