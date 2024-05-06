.PHONY: image
image:
ifndef IMAGE
	$(error IMAGE is not defined. Please define it before running make.)
endif


.PHONY: bash
bash: image
	podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} bash

.PHONY: server
server: image
	podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} \
		bundle exec jekyll serve --host 0.0.0.0 --incremental --drafts \
		--livereload --destination /tmp/ckardaris.github.io/


.PHONY: build
build: image
	podman run --security-opt label=disable --rm -v $PWD:/app ${IMAGE} \
		bundle exec jekyll build

.PHONY: deploy
deploy:
	@./scripts/deploy.sh

.PHONY: thumbnails
thumbnails:
	@./scripts/make_thumbnails.sh

.PHONY: diff
diff:
	@./scripts/diff_upstream.sh
