#!/usr/bin/env bash
mkdir -p photography/thumbnails/{400x400,800x800}
cd photography

do_convert() {
    for file in *
    do
        [[ -d "$file" ]] && continue
        line=".............................................."
        printf "%s %s" "[$1] $file" ${line:${#file}}
        [[ -f thumbnails/$1/$file ]] && echo Skipping && continue
        convert "$file" -resize $1 thumbnails/$1/$file
        echo OK
    done
}

do_convert 400x400
do_convert 800x800
