#!/usr/bin/env bash

set -eo pipefail
cd $(git rev-parse --show-toplevel)


if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=$(git hash-object -t tree /dev/null)
fi

./scripts/make-thumbnails.sh
git add ./photography/thumbnails/*

exec git diff-index --check --cached $against --
