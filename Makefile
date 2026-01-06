.PHONY: image
image:
ifndef IMAGE
	$(error IMAGE is not defined. Please define it before running make.)
endif

.PHONY: setup
setup:
	rm -f .git/hooks/post-commit
	rm -f .git/hooks/pre-commit
	ln -sf ../../_scripts/post-commit.sh .git/hooks/post-commit
	ln -sf ../../_scripts/pre-commit.sh .git/hooks/pre-commit

.PHONY: svg
svg:
	fd .svg assets -x sh -c 'printf "%s: " {} && svgcleaner --multipass {} {} 2>&1'

.PHONY: bash
bash: image svg
	podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} \
		sh -c 'bundle exec jekyll build && bash'

.PHONY: server
server: image svg
	podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} \
		bundle exec jekyll serve --host 0.0.0.0 --incremental --drafts \
		--livereload --destination /tmp/ckardaris.github.io/


.PHONY: build
build: image svg
	podman run --security-opt label=disable --rm -v ${PWD}:/app ${IMAGE} \
		bundle exec jekyll build

.PHONY: deploy
deploy:
	@./_scripts/deploy.sh

.PHONY: responsive
responsive:
	@./_scripts/make-responsive.sh
