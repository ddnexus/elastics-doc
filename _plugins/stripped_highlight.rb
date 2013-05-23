module Jekyll
  module Tags
    class StrippedHighlightBlock < HighlightBlock

      def render_pygments(context, code)
        code =~ /^(\s*)/
        strip = $1.length - 1
        super context, code.split("\n").map{|l| l.gsub(/^\s{#{strip}}/, '')}.join("\n")
      end


    end
  end
end

Liquid::Template.register_tag('shighlight', Jekyll::Tags::StrippedHighlightBlock)
