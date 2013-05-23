#   [google]: http://www.google.com  "Google it!"
#   [wiki]: http://wikipedia.org  "Online Encyclopedia"
#   [id]: url  "tooltip"
#
# You can now reference these links in any markdown file.
# For example:
# [Google][google] is a popular search engine and [Wikipedia][wiki] an
# online encyclopedia.

module Jekyll
  module Converters
    class Markdown < Converter

      @@refs_content = begin
                         refs_path = File.join(Jekyll.configuration({})['source'], '_references.md')
                         File.read(refs_path) if File.exist?(refs_path)
                       end

      alias_method :original_convert, :convert
      def convert(content)
        original_convert "#{content}\n#{@@refs_content}"
      end

    end
  end
end
