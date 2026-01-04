#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

base_include_dir="$(realpath _includes/responsive)"
[[ -z "$base_include_dir" ]] && exit 1
mkdir -p "$base_include_dir"
export base_include_dir

base_asset_path="assets/responsive"
export base_asset_path

base_asset_dir="$(realpath "$base_asset_path")"
[[ -z "$base_asset_dir" ]] && exit 1
mkdir -p "$base_asset_dir"
export base_asset_dir


function do_convert() {
    file="${1:?}"
    original="$(identify -format "%w" "$file")"
    srcset=""

    # Create files based on an original.
    #
    # Input:
    # path/to/file.jpg
    #
    # Output:
    # assets/responsive/path/to/240.file.jpg
    # assets/responsive/path/to/400.file.jpg
    # assets/responsive/path/to/...
    #
    rel_dir="$(dirname "$file")"
    name="$(basename "$file")"
    file_asset_dir="$base_asset_dir/$rel_dir"
    mkdir -p "$file_asset_dir"

    # Create srcset file based on an original
    # Input:
    # path/to/file.jpg
    #
    # Output:
    # _includes/responsive/path/to/file.jpg/srcset
    #
    file_include_dir="$base_include_dir/$file"
    mkdir -p "$file_include_dir"

    for w in {240,400,800,1200,1600,2400}
    do
        image="$file_asset_dir/$w.$name"
        printf "[%4s] %s..." "$w" "$file"
        [[ "$w" -ge "$original" ]] && echo TOO WIDE && continue

        srcset+="/$base_asset_path/$rel_dir/$w.$name ${w}w,\n"
        [[ -f "$image" ]] && echo GENERATED && continue

        magick "$file" -resize "${w}x" "$image"
        echo OK
    done
    srcset+="/assets/$file ${original}w\n"
    printf "$srcset" > "$file_include_dir/srcset"
}
export -f do_convert

cd assets
fd . --type f photography images -x sh -c 'do_convert {}'
