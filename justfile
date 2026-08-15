image:
    : ${IMAGE:?}

setup:
    podman build -t ckardaris.com .
    rm -f .git/hooks/post-commit
    rm -f .git/hooks/pre-commit
    ln -sf ../../_scripts/post-commit.sh .git/hooks/post-commit
    ln -sf ../../_scripts/pre-commit.sh .git/hooks/pre-commit
    git clone git@github.com:ckardaris/ckardaris.github.io.git _site

comments:
    ./_scripts/make_comments.py

feeds:
    ./_scripts/make_feeds.py

format:
    fd py _scripts -x ruff format

add-comment:
    ./_scripts/add-comment.sh

change-password:
    ./_scripts/change-password.sh

svg:
    fd .svg -x sh -c 'printf "%s: " {} && svgcleaner --multipass {} {} 2>&1'

bash: image svg
    podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} \
        sh -c 'bundle exec jekyll build && bash'

server: image svg
    podman run --security-opt label=disable --rm -it -p 4000:4000 -p 35729:35729 -v ${PWD}:/app ${IMAGE} \
        bundle exec jekyll serve --host 0.0.0.0 --incremental --drafts \
        --livereload --destination /tmp/ckardaris.com/


build: image svg
    podman run --security-opt label=disable --rm -v ${PWD}:/app ${IMAGE} \
        bundle exec jekyll build

deploy:
    ./_scripts/deploy.sh

responsive:
    ./_scripts/make-responsive.sh

check-commit:
    git log -n1
    (cd _site; git log -n1)

draft *args:
    ./_scripts/make-draft.sh {{ args }}
