.PHONY: server
server:
	bundle exec jekyll server

.PHONY: draft
draft:
	bundle exec jekyll server --drafts

.PHONY: thumbnails
thumbnails:
	@./scripts/make_thumbnails.sh

.PHONY: diff
diff:
	@./scripts/diff_upstream.sh
