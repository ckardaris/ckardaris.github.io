.PHONY: server
server:
	bundle exec jekyll server

.PHONY: thumbnails
thumbnails:
	@./scripts/make_thumbnails.sh
