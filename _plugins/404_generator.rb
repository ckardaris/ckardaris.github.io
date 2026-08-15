require "find"
require "pathname"

module Jekyll

  class Assets404Generator < Generator
    safe true
    priority :normal
    Targets = ["assets", "flatpak"]

    def generate(site)
      app_path = site.source
      Targets.each do |target|
        base_path = File.join(app_path, target)
        next unless Dir.exist?(base_path)
        Find.find(base_path) do |path|
          next unless File.directory?(path)
          relative_path = Pathname.new(path).relative_path_from(app_path).to_s()
          site.pages << GeneratedPage.new(site, relative_path)
        end
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
      Jekyll.logger.info "\r[404_generator.rb] Generating: #{@dir}/index.html"
      self.process(@name)
      self.data = {
        "layout" => "404",
      }
    end
  end
end
