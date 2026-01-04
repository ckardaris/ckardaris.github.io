#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

include_dir="$(realpath _includes/responsive)"
[[ -z "$include_dir" ]] && exit 1
export include_dir

function do_convert() {
    base="${1:?}"
    file="${2:?}"
    original="$(identify -format "%w" "$file")"
    srcset=""
    for w in {240,400,800,1200,1600,2400}
    do
        [[ "$w" -ge "$original" ]] && break
        dir="responsive/$w"
        mkdir -p "$dir"
        image="$dir/$file"
        printf "[%s] %s..." "$w" "$file"
        srcset+="/$base/$image ${w}w,\n"
        [[ -f "$image" ]] && echo Skipping && continue
        magick "$file" -resize "${w}x" "$image"
        echo OK
    done
    srcset+="/$base/$file ${original}w\n"
    mkdir -p "$include_dir/$base"
    printf "$srcset" > "$include_dir/$base/$file"
}
export -f do_convert

cd photography
fd --type f --max-depth 1 -x sh -c 'do_convert photography {}'

cd ../assets/images
fd --type f --max-depth 1 -x sh -c 'do_convert assets/images {}'
