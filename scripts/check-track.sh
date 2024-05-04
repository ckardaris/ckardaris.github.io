#!/usr/bin/env bash

set -e
sources=$(git log -n 1 --format="%H")
cd _site
main=$(git log -n 1 --format="%s")
if [[ "Deploy $sources" != "$main" ]]
then
    echo "Deploy branch does not track the sources branch."
    exit 1
fi
