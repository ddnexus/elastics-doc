module Jekyll
  module Tags
    class StrippedHighlightBlock < HighlightBlock

      def render_pygments(code, is_safe=true)
        strip = 6
        super(code.split("\n").map{|l| l.gsub(/^\s{#{strip}}/, '')}.join("\n"), is_safe)
      end


    end
  end
end

Liquid::Template.register_tag('shighlight', Jekyll::Tags::StrippedHighlightBlock)
