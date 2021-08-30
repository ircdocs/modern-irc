# written by daniel oaks
# released under cc0 public domain

# this lets you easily insert headers for numerics/commands/isupport and link to them
#
# {% commandheader WHO %} and {% messageheader WHO %}
#   - create the WHO message header, with an appropriate ID
#
# {% command WHO %} and {% message WHO %}
#   - link to the WHO message
#
# {% numericheader RPL_WELCOME %}
#   - create the RPL_WELCOME numeric header
#
# {% numeric RPL_WELCOME %}
#   - link to the RPL_WELCOME numeric

def slug(input)
  input.strip.gsub(/\s+/, ' ')
end

def numericAnchor(name, numeric)
  "#{name.gsub(/_/, '').downcase}-#{numeric}"
end

module IRCdocsPlugin
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

  class NumericHeaderTag < Liquid::Tag
    def initialize(name, params, tokens)
      super
      @id = slug(params)
    end

    def render(context)
      super

      info = context.registers[:site].data['modern']['numerics'][@id]
      if info == nil
        raise "Numeric [#{@id}] is not defined in modern.yml"
      end

      "<h3 id=\"#{numericAnchor(@id, info['numeric'])}\"><code>#{@id} (#{info['numeric']})</code></h3>"
    end
  end

  class NumericTag < Liquid::Tag
    def initialize(name, params, tokens)
      super
      @id = slug(params)
    end

    def render(context)
      super

      info = context.registers[:site].data['modern']['numerics'][@id]
      if info == nil
        raise "Numeric [#{@id}] is not defined in modern.yml"
      end

      "<a href=\"##{numericAnchor(@id, info['numeric'])}\"><code>#{@id}</code></a> <code>(#{info['numeric']})</code>"
    end
  end
end

Liquid::Template.register_tag('messageheader', IRCdocsPlugin::MessageHeaderTag)
Liquid::Template.register_tag('commandheader', IRCdocsPlugin::MessageHeaderTag)
Liquid::Template.register_tag('message', IRCdocsPlugin::MessageTag)
Liquid::Template.register_tag('command', IRCdocsPlugin::MessageTag)
Liquid::Template.register_tag('numericheader', IRCdocsPlugin::NumericHeaderTag)
Liquid::Template.register_tag('numeric', IRCdocsPlugin::NumericTag)
