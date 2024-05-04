.PHONY: image
image:
ifndef IMAGE
	$(error IMAGE is not defined. Please define it before running make.)
endif

.PHONY: server
server: image
	podman run --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE}

.PHONY: build
build: image
	podman run --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} bundle exec jekyll build

.PHONY: deploy
deploy:
	@./scripts/deploy.sh

.PHONY: thumbnails
thumbnails:
	@./scripts/make_thumbnails.sh

.PHONY: diff
diff:
	@./scripts/diff_upstream.sh
