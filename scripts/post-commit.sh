#!/usr/bin/env bash

hash=$(git log -n 1 --format="%H")
cd _site
if [[ ! -d .git ]]
then
    git init
fi
git add *
touch .nojekyll
git add .nojekyll
git log -n 1 &>/dev/null && amend="--amend" || amend=
git commit $amend -m "Deploy $hash"
