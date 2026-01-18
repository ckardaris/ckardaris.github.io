#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Save yaml clipboard content.
tmp="$(mktemp)"
xclip -o -sel clip > "$tmp"

# Check validity of the yaml file.
yq "$tmp" > /dev/null

read -e -p "email: " email
read -e -p "date: " date

: "${email:?}"
: "${date:?}"

# Check date formating.
# Check numbers of characters (leading zeros should always be included).
# YYYY-mm-dd HH-MM
if ! test "${#date}" == 16
then
    echo Date must be in the format YYYY-mm-dd HH:MM
    exit 1
fi
# Check format using python.
python3 -c "import datetime; datetime.datetime.strptime('$date',  '%Y-%m-%d %H:%M')"

name="$(yq ".name" "$tmp")"
post="$(yq ".post" "$tmp")"
repliesTo="$(yq ".repliesTo" "$tmp")"
comment="$(yq ".comment" "$tmp")"

: "${name:?}"
: "${post:?}"
: "${comment:?}"

# Calculate file SHA based on the contents of the email.
file_sha="$(printf "%s%s%s" "$post" "$repliesTo" "$comment" | sha256sum | cut -d ' ' -f 1)"

# Check if the message is already processed.
mkdir -p _emails
file="_emails/$file_sha.yaml"
[[ -f "$file" ]] && echo Email already exists: "$file" && exit 1

# Calculate email SHA to store in the public git repository.
email_sha="$(printf "%s" "$email" | sha256sum | cut -d ' ' -f 1)"


emails="$(ls -1 _emails | wc -l)"
id="$(( emails + 1 ))"

# Update name for email in all comments.
if [[ -n "$name" ]] && [[ "$emails" -gt 0 ]]
then

    # Check that 'name' is not linked to another email.
    mapfile -t other_emails < <(rg --files-without-match "email: $email_sha" _emails)
    for email in "${other_emails[@]}"
    do
        if [[ "$name" == "$(yq ".name" "$email")" ]]
        then
            echo Name is linked to another email: $name
            exit 1
        fi
    done

    mapfile -t my_emails < <(rg --files-with-matches "email: $email_sha" _emails)
    for email in "${my_emails[@]}"
    do
        yq -i ".name = \"$name\"" "$email"
    done
fi

mv "$tmp" "$file"
yq -i ".date = \"$date\"" "$file"
yq -i ".id = $id" "$file"
yq -i ".email = \"$email_sha\"" "$file"

if ! make comments
then
    exit_code="$?"
    rm "$file"
    exit "$exit_code"
fi
