module Jekyll
  module RewriteMdLinksFilter
    def rewrite_md_links(content)
      content = content.gsub(/.md#(.*)\)/) { |match| match.tr("_", "") }
      content = content.gsub(/[0-9]\.([a-z\-]*)\.md/, '\1.html')
      content = content.gsub(/\(\.\.\/(.*)\)/, '(https://github.com/vsergeev/luaradio/tree/master/\1)')
      content
    end
  end
end
Liquid::Template.register_filter(Jekyll::RewriteMdLinksFilter)
