require 'find'
require 'pathname'

class DocTree < Tree::TreeNode

  def safe_add(child, at_index=nil)
    return @children_hash[child.name] if @children_hash.has_key?(child.name)
    at_index.nil? ? add(child) : add(child, at_index)
  end

  def <=(child)
    safe_add(child)
  end

  def configuration
    self.class.configuration
  end

  def self.configuration
    @configuration ||= Jekyll.configuration({})['doc_tree']
  end

  def self.tree
    @tree ||= generate_tree
  end

  def title
    content[:title]
  end

  def short_title
    title && title.sub(/^[\w-]+ - /, '')
  end

  def self.find_by_doc_ref(ref)
    tree.each{|n| return n if !n.content.blank? && n.content[:doc_ref] == ref}
    nil
  end

  def self.find_by_name(name)
    tree.each{|n| return n if n.name == name}
    nil
  end

  private

  def self.generate_tree
    doc_source_path = Pathname.new configuration['doc_source_path']
    source_path     = Pathname.new Jekyll.configuration({})['source']
    doc_path        = '/' + doc_source_path.relative_path_from(source_path).to_s
    tree            = DocTree.new(doc_path, {:title => 'FlexDoc'})
    Find.find(doc_source_path) do |p|
      next if doc_source_path == p   # discard root
      path      = Pathname.new p
      rel_path  = path.relative_path_from(doc_source_path)
      title = if path.directory?
                rel_path.basename('.*').to_s.sub(/^\d+-/, '')
              else
                data = YAML.safe_load($1) if path.read =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
                data && data['title']
              end || 'UNTITLED'
      title.gsub!(/-([A-Z])/, ' \1') # remove dashes
      fragments = rel_path.to_s.split('/')
      # replace the extname with '.html' if file
      fragments << fragments.pop.sub(/#{path.extname}$/, '.html') unless path.directory?
      fragments.inject([tree, doc_path, '']) do |memo, f|
        node, node_path, doc_ref = memo
        node_path += "/#{f}"
        # generate the doc reference (e.g 1.3.2)
        doc_ref += f =~ /^(\d+)-/ ? ".#{$1}" : ''
        doc_ref.sub!(/^\./, '')
        [ node <= new(node_path, :title   => title,
                                 :doc_ref => doc_ref),
          node_path,
          doc_ref ]
      end
    end
    tree
  end

end

module Jekyll

  class NavMenu < Liquid::Tag

    def render(context)
      @nav_menu ||= begin
                      tree = DocTree.tree
                      %(<ul id="nav-menu" class="menu_h_list">#{render_node(tree)}</ul>)
                    end
    end

  private

    def render_node(node)
      wrap(:li, node) do
        if node.has_children?
          out = ''
          arrow = node.is_root? || node.parent.is_root? ? '' : '<div class="arrow right"></div>'
          out << %(<a href="#" class="isLabel">#{node.short_title}</a>#{arrow}) unless node.is_root?
          out << wrap(:ul, node) do
            node.children.map do |child|
              render_node(child)
            end.join
          end
          out
        else
          %(<a href="#{Helper.baseurl}#{node.name}">#{node.short_title}</a>)
        end
      end
    end

    def wrap(tag, node)
      node.is_root? ? yield : "<#{tag}>#{yield}</#{tag}>"
    end

  end
  Liquid::Template.register_tag('nav_menu', Jekyll::NavMenu)


  class DocLink < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      links = @text.split(',')
      out = "(see "
      tags = links.map do |ref_str|
               ref_str.strip!
               link, title = ref_str.split(/\s+/, 2)
               ref, anchor = link.split('#')
               node        = DocTree.find_by_doc_ref(ref)
               if node.nil?
                 Jekyll::Logger.info 'BROKEN-LINK:', ref_str.strip
                 return %(<span class="broken-link">&lt;BROKEN LINK (#{ref_str.strip})&gt;</span>)
               end
               label       = !title.blank? && title.strip || !anchor.blank? && anchor.titleize || node.short_title
               %|<a href="#{Helper.baseurl}#{node.name}#{anchor && '#'+anchor}">#{label}</a>|
             end
      last_tag = tags.pop if tags.size > 1
      out << tags.join(', ')
      out << " and #{last_tag}" if last_tag
      out << ')'
      out
    end

  end
  Liquid::Template.register_tag('see', Jekyll::DocLink)


  class Breadcrumb < Liquid::Tag

    def render(context)
      page_url  = context.environments.first['page']['url']
      page_node = DocTree.find_by_name(page_url)
      out       = page_node.parentage.reverse.map do |node|
                    node.short_title
                  end
      out << page_node.short_title
      out.map{|i|"<span>#{i}</span>"}.join(' &gt; ')
    end

  end
  Liquid::Template.register_tag('breadcrumb', Jekyll::Breadcrumb)

end


