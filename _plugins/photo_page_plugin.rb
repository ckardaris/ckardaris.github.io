module Jekyll
  class PhotoPagesGenerator < Generator
    safe true
    priority :normal

    def generate(site)
      photos = site.data['photos']
      photos.each_with_index do |photo, index|
        previous_photo = photos[(index - 1) % photos.size]
        next_photo = photos[(index + 1) % photos.size]

        site.pages << PhotoPage.new(site, photo, previous_photo, next_photo, index)
      end
    end
  end

  class PhotoPage < Page
    def initialize(site, photo, previous_photo, next_photo, index)
      @site = site
      @base = site.source
      @dir = "/photography/" + photo["name"]
      @basename = 'index'      # filename without the extension.
      @ext      = '.html'      # the extension.
      @name     = 'index.html' # basically @basename + @ext.

      self.process(@name)
      self.data = {
        'layout' => 'photo_page',
        'title' => photo["caption"],
        'photo' => photo,
        'previous_photo' => previous_photo,
        'next_photo' => next_photo,
        'index' => index + 1  # increment to start from 1,
      }
    end
  end
end
