# _plugins/flatpak_metainfo_generator.rb
require 'nokogiri'
require 'open-uri'

module Jekyll
  class FlatpakPage < Page
    def initialize(site, name, data)
      @site = site
      @base = site.source
      @dir  = "/flatpak/applications/" + name
      @basename = 'index'
      @ext      = '.html'
      @name = 'index.html'

      self.process(@name)
      self.data = {
        'layout' => 'flatpak_page',
        'title' => name,
        'application' => name,
        'metainfo' => data
      }
    end
  end

  class FlatpakMetainfoGenerator < Generator
    safe false
    priority :high

    def generate(site)
      projects = site.data['software']
      flatpaks = {}

      projects.each do |project|
        next unless project['flatpak']['available']

        metainfo = project['flatpak']['metainfo']
        next unless metainfo

        begin
          xml = URI.open(metainfo).read
          doc = Nokogiri::XML(xml)
          hash = xml_to_hash(doc.root)
          name = project['name']
        rescue => e
          Jekyll.logger.warn 'FlatpakMetainfoGenerator:', "Failed for #{name}: #{e.message}"
          next
        end

        hash['svg'] = project['svg']
        hash['flatpakref'] = project['flatpak']['flatpakref']

        flatpaks[name] = hash

        site.pages << FlatpakPage.new(site, name, hash)
      end

      site.data['flatpaks'] = flatpaks
    end

    private

    # Recursively converts an Nokogiri::XML::Node into a hash/array structure
    def xml_to_hash(node)
      if node.name == 'description'
        return node.children.to_xml.strip
      end

      attrs = node.attributes.transform_values(&:value)

      if node.element_children.empty?
        text = node.text.strip
        return attrs.empty? ? text : attrs.merge('text' => text)
      end

      result = attrs.dup
      node.element_children.each do |child|
        value = xml_to_hash(child)
        if result[child.name]
          result[child.name] = [result[child.name]] unless result[child.name].is_a?(Array)
          result[child.name] << value
        else
          result[child.name] = value
        end
      end
      result
    end
  end
end
