#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Save yaml clipboard content.
tmp="$(mktemp)"
cliptext="$(xclip -o -sel clip)"
if printf "%s" "$cliptext" | rg "BEGIN PGP MESSAGE" &>/dev/null
then
    printf "%s" "$cliptext" | gpg --decrypt > "$tmp"
else
    printf "%s" "$cliptext" > "$tmp"
fi

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
: "${name:?}" && test "$name" != "null"

password="$(yq ".password" "$tmp")"
: "${password:?}" && test "$password" != "null"

post="$(yq ".post" "$tmp")"
: "${post:?}" && test "$post" != "null"

repliesTo="$(yq ".repliesTo" "$tmp")"

comment="$(yq ".comment" "$tmp")"
: "${comment:?}" && test "$comment" != "null"

# Calculate email SHA to store in the public git repository.
email_sha="$(printf "%s%s" "$email" "${EMAIL_SALT:?}" | sha256sum | cut -d ' ' -f 1)"

# Calculate auth SHA to store in the public git repository.
auth_sha="$(printf "%s%s%s" "$email" "$password" "${EMAIL_SALT:?}" | sha256sum | cut -d ' ' -f 1)"
: "${auth_sha:?}"

mkdir -p _comments
comments_count="$(ls -1 _comments | wc -l)"

# Check name/email validity and update name for email in all comments.
if [[ "$comments_count" -gt 0 ]]
then
    # Check that 'name' is not linked to another email.
    mapfile -t other_comments < <(rg --files-without-match "email: $email_sha" _comments)
    for c in "${other_comments[@]}"
    do
        comment_name="$(yq ".name" "$c")"
        if [[ "$name" == "${comment_name:?}" ]]
        then
            echo Name is linked to another email account.
            exit 1
        fi
    done

    mapfile -t my_comments < <(rg --files-with-matches "email: $email_sha" _comments)
    for c in "${my_comments[@]}"
    do
        comment_auth_sha="$(yq ".auth" "$c")"
        if [[ "$auth_sha" != "${comment_auth_sha:?}" ]]
        then
            # Password for this email address is wrong.
            echo Authentication failed.
            exit 1
        fi

        comment_name="$(yq ".name" "$c")"
        if [[ "$name" == "${comment_name:?}" ]]
        then
            # User does not change their name.
            break
        fi

        yq -i ".name = \"$name\"" "$c"
    done
fi

# Calculate file SHA based on the contents of the email.
file_sha="$(printf "%s%s%s%s" "$email_sha" "$post" "$repliesTo" "$comment" | sha256sum | cut -d ' ' -f 1)"

# Check if the message is already processed.
mkdir -p _comments
file="_comments/$file_sha.yaml"
[[ -f "$file" ]] && echo Email already exists. && exit 1

mv "$tmp" "$file"
yq -i ".date = \"$date\"" "$file"
yq -i ".id = $(( comments_count + 1 ))" "$file"
yq -i ".email = \"$email_sha\"" "$file"
yq -i ".auth = \"$auth_sha\"" "$file"

if ! make comments
then
    exit_code="$?"
    rm "$file"
    exit "$exit_code"
fi
