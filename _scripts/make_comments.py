#!/usr/bin/env python3

from pathlib import Path
import hashlib
import yaml

emails = Path("_comments")
comments = []

for file_path in emails.glob("*.yaml"):
    with open(file_path, "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            comments.append(data)

            # null is the value that 'yq' returns for non-existing keys.
            assert (
                file_path.stem
                == hashlib.sha256(
                    (
                        data["email"]
                        + data["post"]
                        + str(data.get("repliesTo", "null"))
                        + str(data["comment"])
                    ).encode("utf-8")
                ).hexdigest()
            )

        except yaml.YAMLError as e:
            print(f"Error parsing {file_path}: {e}")
            exit(1)

for comment in comments:
    assert isinstance(comment["id"], int)

comments.sort(key=lambda x: x["id"])

for comment in comments:
    # Recursively calculate the ancestor comment IDs of the current comment.
    def fill_ancestors(ancestor):
        for comment in [
            x for x in comments if x.get("repliesTo", None) == ancestor["id"]
        ]:
            comment["ancestors"] = ancestor["ancestors"] + [ancestor["id"]]
            fill_ancestors(comment)

    root_comments = [x for x in comments if not x.get("repliesTo", None)]
    for root_comment in root_comments:
        root_comment["ancestors"] = []
        fill_ancestors(root_comment)

for comment in comments:
    if comment.get("repliesTo", None):
        repliesTo = comment["repliesTo"]
        if sum(1 for x in comments if x["id"] == repliesTo) != 1:
            print(comment)
            print(f"Non-existing comment ID ('repliesTo': {repliesTo}).")
            exit(1)

# Sort comments based on their ancestors.
comments.sort(key=lambda x: x["ancestors"] + [x["id"]])

# Remove 'repliesTo' key, since the information is already present
# in the ancestors list (last # element).
for comment in comments:
    comment.pop("repliesTo", None)

for i, comment in enumerate(comments):
    next_comment = next(
        (
            x
            for x in comments[i + 1 :]
            if (x["post"], x["ancestors"]) == (comment["post"], comment["ancestors"])
        ),
        None,
    )
    if next_comment:
        assert comment != next_comment
        comment["next"] = next_comment["id"]
        next_comment["prev"] = comment["id"]


with open("_data/comments.yaml", "w") as f:
    yaml.dump(comments, f)
