#!/usr/bin/env bash

set -e

./_scripts/check-track.sh
echo Pushing sources...

set +e
git push origin sources
cd _site
[[ ! -d .git ]] && echo No git directory found... && exit 1
git remote add origin git@github.com:ckardaris/ckardaris.github.io.git &>/dev/null
echo Pushing static site...
! git log -n 1 &>/dev/null && echo No commit found... && exit 1
git push origin main
