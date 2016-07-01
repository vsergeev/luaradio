module Jekyll
  class MarkdownTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text.strip
    end
    def render(context)
      File.read(File.join(Dir.pwd, '_includes', @text))
    end
  end
end
Liquid::Template.register_tag('markdown', Jekyll::MarkdownTag)
