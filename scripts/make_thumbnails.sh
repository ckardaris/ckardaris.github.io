#!/usr/bin/env bash
mkdir -p photography/thumbnails
cd photography
for file in *
do
    printf "%s..." "$file"
    [[ -d "$file" ]] && continue
    [[ -f thumbnails/$file ]] && echo Skipping && continue
    convert "$file" -resize 400x400 thumbnails/$file
    echo OK
done
