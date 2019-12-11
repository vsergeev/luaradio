module Jekyll
  class BaseTag < Liquid::Tag
    def initialize(tag_name, params, tokens)
      super
    end

    def render(context)
      depth = context['page']['url'].count('/')

      if depth <= 1 then
        "."
      else
        ("../" * (depth-1))[0..-2]
      end
    end
  end
end

Liquid::Template.register_tag('base', Jekyll::BaseTag)
