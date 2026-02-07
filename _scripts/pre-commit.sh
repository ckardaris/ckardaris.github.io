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

./_scripts/make-responsive.sh
git add ./assets/*

# Format python scripts
fd .py _scripts -x ruff format

./_scripts/make_feeds.py
git add blog

exec git diff-index --check --cached $against --
