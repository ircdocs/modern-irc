# written by daniel oaks
# released under cc0 public domain

# this lets you easily insert headers with custom IDs.
#
# e.g.
#  tag:
#   {% h3 message-VERSION %}_VERSION_ message{% endh3 %}
#  makes:
#   <h3 id="message-VERSION"><em>VERSION</em> message</h3>

def slug(input)
  input.strip.gsub(/\s+/, " ")
end

module Jekyll
  class HeadingTagBlock < Liquid::Block
    def initialize(name, params, tokens)
      super
      @name = name
      @id = params
    end

    def render(context)
      text = super

      # markdowify text, then remove <p> tag.
      # see also https://talk.jekyllrb.com/t/markdown-parsing-order-in-custom-liquid-tags/4397/3
      text = context.registers[:site].find_converter_instance(
        Jekyll::Converters::Markdown
      ).convert(text).gsub(/<\/?p[^>]*>/, "").strip

      "<#{@name} id=\"#{slug(@id)}\">#{text}</#{@name}>"
    end
  end
end

Liquid::Template.register_tag('h1', Jekyll::HeadingTagBlock)
Liquid::Template.register_tag('h2', Jekyll::HeadingTagBlock)
Liquid::Template.register_tag('h3', Jekyll::HeadingTagBlock)
Liquid::Template.register_tag('h4', Jekyll::HeadingTagBlock)
Liquid::Template.register_tag('h5', Jekyll::HeadingTagBlock)
