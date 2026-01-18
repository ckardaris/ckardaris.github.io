#!/usr/bin/env python3

from pathlib import Path
import hashlib
import yaml

emails = Path("_comments")
comments = {}

for file_path in emails.glob("*.yaml"):
    with open(file_path, "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            post = data["post"]

            if post not in comments:
                comments[post] = []

            comments[post].append(data)

            file_sha = file_path.stem
            # null is the value that 'yq' returns for non-existing keys.
            check_sha = hashlib.sha256((data["post"] + str(data.get("repliesTo", "null")) + str(data["comment"]) + data["email"]).encode("utf-8")).hexdigest()
            assert file_sha == check_sha

        except yaml.YAMLError as e:
            print(f"Error parsing {file_path}: {e}")
            exit(1)

for post, post_comments in comments.items():

    # Recursively calculate the ancestor comment IDs of the current comment.
    def fill_ancestors(comment):
        for post_comment in [x for x in post_comments if x.get("repliesTo", None) == comment["id"]]:
            post_comment["ancestors"] = comment["ancestors"] + [comment["id"]]
            fill_ancestors(post_comment)

    root_comments = [x for x in post_comments if not x.get("repliesTo", None)]
    for root_comment in root_comments:
        root_comment["ancestors"] = []
        fill_ancestors(root_comment)

    for i, comment in enumerate(post_comments):
        if comment.get("repliesTo", None):
            repliesTo = comment["repliesTo"]
            if len([x for x in post_comments if x["id"] == repliesTo]) == 0:
                print(comment)
                print(f"Non-existing comment ID ('repliesTo': {repliesTo}).")
                exit(1)

    # Remove 'repliesTo' key, since the information is already present
    # in the ancestors list (last # element).
    comments[post] = sorted(post_comments, key = lambda x: x["ancestors"] + [x["id"]])
    for comment in comments[post]:
        comment.pop("repliesTo", None)

    for i, post_comment in enumerate(comments[post]):
        next_comment = next((x for x in comments[post][i+1:] if x["ancestors"] == post_comment["ancestors"]), None)
        if next_comment:
            assert post_comment != next_comment
            post_comment["next"] = next_comment["id"]
            next_comment["prev"] = post_comment["id"]


with open("_data/comments.yaml", "w") as f:
    yaml.dump(comments, f)
