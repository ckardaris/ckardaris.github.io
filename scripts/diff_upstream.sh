#!/usr/bin/env bash
cd $(git rev-parse --show-toplevel)
minima=$(bundle info --path minima)
for file in $(find)
do
    upstream="$minima/$file"
    [[ ! -f "$upstream" ]] && continue
    echo ======= $file =========
    diff --color=always "$upstream" "$file"
done
