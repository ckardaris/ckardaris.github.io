#!/usr/bin/env bash
cd photography

function do_convert {
    line=".............................................."
    file="$2"
    printf "%s %s" "[$1] $file" ${line:${#file}}
    [[ -f thumbnails/$1/$file ]] && echo Skipping && return
    magick "$file" -resize $1 thumbnails/$1/$file
    echo OK
}
export -f do_convert

convert_all() {
    mkdir -p thumbnails/"$1"
    fd --type f --max-depth 1 -x sh -c "do_convert $1 {}"
}

convert_all 400x400
convert_all 800x800
convert_all 1200x1200
convert_all 1600x1600
convert_all 2400x2400
