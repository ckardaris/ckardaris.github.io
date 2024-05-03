ifndef IMAGE
    $(error IMAGE is not defined. Please define it before running make.)
endif

.PHONY: server
server:
	podman run --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE}

.PHONY: draft
draft:
	bundle exec jekyll server --drafts

.PHONY: thumbnails
thumbnails:
	@./scripts/make_thumbnails.sh

.PHONY: diff
diff:
	@./scripts/diff_upstream.sh
