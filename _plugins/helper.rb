module Helper
  extend self

  def baseurl
    Jekyll.configuration({})['baseurl']
  end

  def assets_path
    conf = Jekyll.configuration({})['asset_pipeline']
    "/#{conf['display_path'] || conf['output_path']}"
  end

  def see(text)
    links = text.split(',')
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


  def api_groups
    { 'document_api' => 'Document API',
      'indices_api'  => 'Indices API',
      'search_api'   => 'Search API',
      'cat_api'      => 'Cat API',
      'cluster_api'  => 'Cluster API' }
  end

end
