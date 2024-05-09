---
layout: post
title: ChatGPT and the web ignorant
tags: html css chatgpt ruby jekyll
---

The first time I used ChatGPT I was astounded. Here was something that felt like
magic. Since then, a lot more information has been made available about LLMs in
general. Us laymen have peeked inside the magician's hat. We know more about
their capabilities and shortcomings. We know that they can hallucinate at times
and that their output should be used with care. But the point still remains;
what ChatGPT and the rest of the LLMs offer is awesome.

I mostly use ChatGPT for my programming tasks. While learning new concepts, it
has mostly replaced searching the web for me. I prefer its clean interface: a
question followed by an answer. Most times the answer is on point, something you
don't get out of a traditional search engine these days. The top-ranked
SEO-heavy posts create an additional burden on me to filter them, which is not
always an easy task, or a worthwhile one. For specific technical matters, I
still prefer to directly visit the reference or documentation websites[^1].

[^1]: I am programming in C++ at work, so I frequently visit
    [cppreference.com](https://cppreference.com).

I first set up this personal website two years ago. I realised that GitHub
pages would be a simple way to go about it. I set up Jekyll and started
tinkering with a theme[^2]. Initially hesitant to begin posting, I uploaded
some of my photography and left it at that.

[^2]: This website is based on the [minima](https://github.com/jekyll/minima)
    theme.

About two weeks ago, I decided that I wanted to bring some life back into it. I
set up my local environment again and started improving the website, bit by bit.
I introduced post tags and tag pages[^3]. I uploaded my first
[post](/blog/2024/05/04/see-you-at-the-library.html).

[^3]: I am using [jekyll-tagging](https://github.com/pattex/jekyll-tagging).

One thing remained and I would be set: a better gallery view for my
[photos](/photography). From the first moment, I wanted to have a grid view.
However, I am not very proficient in CSS and, at the time, I could not make it
work as I wanted. I put my photos in a single column and called it a day.

![Single column photo
gallery](/assets/images/2024-05-06-chatgpt-stories-helping-a-ruby-ignorant-0.png)

[^4]: For the time being of course. Can you really be satisfied with your setup?

Enter ChatGPT.


> I want to put photos in a three column grid. When the screen size reduces, I
> want it to be responsive. What is the proper way to do it?

ChatGPT replied.
``` html
<div class="grid-container">
  <div class="grid-item"><img src="photo1.jpg" alt="Photo 1"></div>
  <div class="grid-item"><img src="photo2.jpg" alt="Photo 2"></div>
  <div class="grid-item"><img src="photo3.jpg" alt="Photo 3"></div>
  <!-- Add more grid items as needed -->
</div>
```
and
``` css
.grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  grid-gap: 10px;
}

.grid-item {
  width: 100%;
}
```
It worked on the first try. I took it from there. I knew how to proceed. I
adjusted my Jekyll templates accordingly and changed the `minmax` value, in
order to fit three photos in the widest layout. I finally had a nicely looking
photo gallery. I even added captions to all the photos. Cool!

![Grid gallery](/assets/images/2024-05-06-chatgpt-stories-helping-a-ruby-ignorant-1.png)

Initially, by clicking on each photo, the original full-size photo was shown. I
thought that this was not very optimal, since a lot of network data needed to be
transferred. Most of my photos are taken with my Nikon D3400 DSLR camera and
their size can be up to 20MB. The solution would be to show some smaller version
of each photo initially, and only display the full-size version after a second
click.

I thought to myself, "I want each photo to have its own page. How do I do
that?". I knew that it was possible to do it. My tags plugin is generating
pages for all post tags.

Enter ChatGPT. Again.

> Let's say I have a list of photos in a Jekyll website as a data file. I want
> to create a page for each photo, where you can see the photo and links to the
> previous and next photo will navigate you along the list.

ChatGPT produced some valid HTML that I could work with, but the rest of the
code was not up to the task. It did not help much with the Jekyll integration
part. After a quick look around the web and the Jekyll documentation, I
understood I needed to write a custom plugin[^5].

[^5]: Maybe there is a more elegant way to do it. Suggestions are welcome.

> Your suggestions so far are not working. I think I need to write a custom
> plugin.

After the usual ChatGPT answer intro, I got the coveted code.

``` rb
module Jekyll
  class PhotoPagesGenerator < Generator
    safe true
    priority :normal

    def generate(site)
      photos = site.data['photos']
      photos.each_with_index do |photo, index|
        previous_photo = index > 0 ? photos[index - 1] : nil
        next_photo = index < photos.size - 1 ? photos[index + 1] : nil

        site.pages << photoPage.new(site, photo, previous_photo, next_photo)
      end
    end
  end

  class photoPage < Page
    def initialize(site, photo, previous_photo, next_photo)
      @site = site
      @base = site.source
      @dir = '' # Set the directory where you want the pages to be generated
      @name = photo['url'] # Use the photo URL as the page name

      self.process(@name)
      self.data = {
        'layout' => 'photo_page',
        'title' => photo['caption'],
        'photo' => photo,
        'previous_photo' => previous_photo,
        'next_photo' => next_photo
      }
    end
  end
end
```
Voila! Once more, I made the necessary edits. I introduced wrapping around after
reaching the end of the photo list, simplified the code, based on the official
Jekyll documentation for generators, and set the correct path for the photos to
be shown.

``` rb
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
      @basename = 'index'
      @ext      = '.html'
      @name     = 'index.html'

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
```

I finally had it. I struggled a little more than with the CSS grid code, but I
had it. A page for every one of my photos. Enthusiastically, I uploaded the
changes.

![Photo page](/assets/images/2024-05-06-chatgpt-stories-helping-a-ruby-ignorant-2.png)

I am really satisfied with the outcome. I find it amazing how helpful ChatGPT
can be, if you have a rough idea of what you want to achieve, you know the right
keywords to use in your query and are willing to play a little with the code
afterwards. And, testament to its value, I consider it as a great companion in
my tech endeavours and look forward to further exploring its powers.
