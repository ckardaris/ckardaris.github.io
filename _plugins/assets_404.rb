require "find"
require "pathname"

module Jekyll
  class Assets404Generator < Generator
    safe true
    priority :normal

    def generate(site)
      app_path = site.source

      base_path = File.join(app_path, "assets")
      return unless Dir.exist?(base_path)

      Find.find(base_path) do |path|
        next unless File.directory?(path)

        relative_path = Pathname.new(path).relative_path_from(app_path).to_s()
        site.pages << GeneratedPage.new(site, relative_path)
      end
    end
  end

  class GeneratedPage < Page
    def initialize(site, path)
      @site = site
      @base = site.source
      @dir  = "/" + path
      @basename = 'index'
      @ext      = '.html'
      @name = "index.html"

      Jekyll.logger.info "\r[assets_404.rb] Generating: #{@dir}/index.html"
      self.process(@name)
      self.data = {
        "layout" => "404",
      }
    end
  end
end
