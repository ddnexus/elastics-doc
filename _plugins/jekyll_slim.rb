# fix needed with jekyll 2.5.3
module Jekyll
  class Layout
    def initialize(site, base, name)
      @site = site
      @base = base
      @name = name
      self.data = {}
      self.process(name)
      self.read_yaml(base, name)
      # we need to set content, because jekyll transform method doesn't do it anymore
      self.content = transform
    end
  end
end
