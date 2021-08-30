# written by daniel oaks
# released under cc0 public domain

# this lets you easily insert headers for numerics/commands/isupport and link to them
#
# {% commandheader WHO %} and {% messageheader WHO %}
#   - create the WHO message header, with an appropriate ID
#
# {% command WHO %} and {% message WHO %}
#   - link to the WHO message.

def slug(input)
  input.strip.gsub(/\s+/, " ")
end

module Jekyll
  class MessageHeaderTag < Liquid::Tag
    def initialize(name, params, tokens)
      super
      @id = slug(params)
    end

    def render(context)
      super

      "<h3 id=\"#{@id}-message\">#{@id} Message</h3>"
    end
  end

  class MessageTag < Liquid::Tag
    def initialize(name, params, tokens)
      super
      @id = slug(params)
    end

    def render(context)
      super

      "<a href=\"##{@id}-message\"><code>#{@id}</code></a>"
    end
  end
end

Liquid::Template.register_tag('messageheader', Jekyll::MessageHeaderTag)
Liquid::Template.register_tag('commandheader', Jekyll::MessageHeaderTag)
Liquid::Template.register_tag('message', Jekyll::MessageTag)
Liquid::Template.register_tag('command', Jekyll::MessageTag)
