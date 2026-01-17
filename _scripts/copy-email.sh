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

# Simple date checking.
if [[ ! "$date" =~ ^20[2-9][0-9]-[0-1][0-9]-[0-3][0-9][[:space:]][0-2][0-9]:[0-5][0-9]$ ]]
then
    echo Wrong date format. Expected \"YYYY-MM-DD HH:MM\"
    exit 1
fi

post="$(yq ".post" "$tmp")"
repliesTo="$(yq ".repliesTo" "$tmp")"
comment="$(yq ".comment" "$tmp")"

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
name="$(yq ".name" "$tmp")"
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
