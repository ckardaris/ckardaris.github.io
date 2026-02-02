FROM docker.io/library/ruby:3.0

WORKDIR /app

COPY Gemfile Gemfile.lock .
RUN bundle install

# Patch jekyll-tagging to correct tag page title.
# https://github.com/pattex/jekyll-tagging/pull/60/files
RUN sed -i \
"/ self.data    = data/a\      self.data['title'] = \"Tag: #{data['tag']}\"" \
/usr/local/bundle/gems/jekyll-tagging-1.1.0/lib/jekyll/tagging.rb

# Patch jekyll-feed to use site.feed.title instead of site.title.
RUN sed -i \
"s:= site.title:= site.feed.title:" \
/usr/local/bundle/gems/jekyll-feed-0.16.0/lib/jekyll-feed/feed.xml
