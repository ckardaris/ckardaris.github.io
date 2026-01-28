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
: "${email:?}"

old_password="$(yq ".old_password" "$tmp")"
: "${old_password:?}" && test "$old_password" != "null"
new_password="$(yq ".new_password" "$tmp")"
: "${new_password:?}" && test "$new_password" != "null"

# Calculate email SHA to store in the public git repository.
email_sha="$(printf "%s%s" "$email" "${EMAIL_SALT:?}" | sha256sum | cut -d ' ' -f 1)"

# Calculate auth SHA to store in the public git repository.
old_auth_sha="$(printf "%s%s%s" "$email" "$old_password" "${EMAIL_SALT:?}" | sha256sum | cut -d ' ' -f 1)"
: "${old_auth_sha:?}"
new_auth_sha="$(printf "%s%s%s" "$email" "$new_password" "${EMAIL_SALT:?}" | sha256sum | cut -d ' ' -f 1)"
: "${new_auth_sha:?}"

mkdir -p _comments
comments_count="$(ls -1 _comments | wc -l)"

# Check name/email validity and update name for email in all comments.
if ! test "$comments_count" -gt 0
then
    echo No comments stored.
    exit 1
fi

# Find a comment from the same email address.
mapfile -t my_comments < <(rg --files-with-matches "email: $email_sha" _comments)

if ! test "${#my_comments[@]}" -gt 0
then
    echo No comments by this email address stored.
    exit 1
fi

comment_auth_sha="$(yq ".auth" "${my_comments[0]}")"
if [[ "$old_auth_sha" != "${comment_auth_sha:?}" ]]
then
    # Password for this email address is wrong.
    echo Authentication failed.
    exit 1
fi

for c in "${my_comments[@]}"
do
    yq -i ".auth = \"$new_auth_sha\"" "$c"
done
