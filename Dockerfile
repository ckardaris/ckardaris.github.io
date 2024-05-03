FROM docker.io/library/ruby:3.0

WORKDIR /app

COPY Gemfile Gemfile.lock .
RUN bundle install

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--incremental", "--drafts", "--livereload"]
