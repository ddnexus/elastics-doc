module Helper
  extend self

  def baseurl
    Jekyll.configuration({})['baseurl']
  end

  def assets_path
    conf = Jekyll.configuration({})['asset_pipeline']
    "/#{conf['display_path'] || conf['output_path']}"
  end

end
