require 'jekyll_asset_pipeline'

module JekyllAssetPipeline

  class ErbConverter < JekyllAssetPipeline::Converter
    def self.filetype
      '.erb'
    end

    def convert
      ERB.new(@content).result
    end
  end

  class CoffeeScriptConverter < JekyllAssetPipeline::Converter
    def self.filetype
      '.coffee'
    end

    def convert
      CoffeeScript.compile(@content)
    end
  end

  class ScssConverter < JekyllAssetPipeline::Converter
    def self.filetype
      '.scss'
    end

    def convert
      Sass::Engine.new(@content, :syntax     => :scss,
                                 :load_paths => %w[./source/_assets/css]).render
    end
  end

  class SassConverter < JekyllAssetPipeline::Converter
    def self.filetype
      '.sass'
    end

    def convert
      Sass::Engine.new(@content, :syntax     => :sass,
                                 :load_paths => %w[./source/_assets/css]).render
    end
  end

  class CssCompressor < JekyllAssetPipeline::Compressor
    def self.filetype
      '.css'
    end

    def compress
      YUI::CssCompressor.new.compress(@content)
    end
  end

  class JavaScriptCompressor < JekyllAssetPipeline::Compressor
    def self.filetype
      '.js'
    end

    def compress
      YUI::JavaScriptCompressor.new(munge: true).compress(@content)
    end
  end

end
