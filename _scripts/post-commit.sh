#!/usr/bin/env bash

make build || exit 1
hash=$(git log -n 1 --format="%H")
cd _site
if [[ ! -d .git ]]
then
    git init
fi
git add *
touch .nojekyll
git add .nojekyll
git commit -m "Deploy $hash"
