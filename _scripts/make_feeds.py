#!/usr/bin/env python3

import sys
import yaml
from os import mkdir
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
from feedgen.feed import FeedGenerator
from markdown import markdown

cwd = Path(__file__).parent


def load_yaml_files() -> None:
    with open(cwd / "../_config.yml", "r", encoding="utf-8") as f:
        try:
            config = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"Error parsing {file_path}: {e}")
            exit(1)
    with open(cwd / "../_data/comments.yaml", "r", encoding="utf-8") as f:
        try:
            comments = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"Error parsing {file_path}: {e}")
            exit(1)
    with open(cwd / "data/post_id_map.yml", "r", encoding="utf-8") as f:
        try:
            post_id_map = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"Error parsing {file_path}: {e}")
            exit(1)
    return config, comments, post_id_map


def parse_date(
    value: str, date_format: str = "%Y-%m-%d %H:%M", timezone: str = "Europe/Berlin"
) -> datetime:
    """
    Parse 'YYYY-MM-DD HH:MM' as Central European local time
    and convert to UTC (required by Atom).
    """
    assert value
    local_dt = datetime.strptime(value, date_format)
    local_dt = local_dt.replace(tzinfo=ZoneInfo(timezone))
    return local_dt.astimezone(ZoneInfo("UTC"))


def comment_url(site_url: str, comment: dict) -> str:
    return f"{site_url}{comment['post']}.html#comment-{comment['id']}"


def markdown_to_html(content: str) -> str:
    html = markdown(
        text=content,
        extensions=[
            "extra",  # tables, fenced code blocks, etc.
            "attr_list",  # {: .class }
            "footnotes",
            "toc",
        ],
    )
    # Strip whitespace from the end of lines.
    html = "\n".join([x.rstrip() for x in html.splitlines()])
    return html


def create_comments_liquid_filter(comments: list[dict]) -> str:
    """
    Take a list of comments, isolate theirs IDs and create a liquid filter.
    """
    liquid = '{% assign selected_comments = "" | split: "" %}\n'
    for comment in comments:
        liquid += (
            "{% assign selected_comments = selected_comments | push: "
            + str(comment["id"])
            + " %}\n"
        )
    liquid += '{% assign comments = site.data.comments | where_exp: "comment", "selected_comments contains comment.id" %}\n'
    return liquid


def create_redirect_page(from_url: str, to_url: str) -> None:
    html_file = cwd / f"..{from_url}.html"
    html_file.write_text(
        f"""<meta http-equiv="refresh" content="0; url={to_url}"/>""", encoding="utf-8"
    )


def create_blog_page(
    permalink: str,
    browser_title: str,
    title: str,
    feed_title: str,
    subtitle: str,
    top_content: str,
    main_content: str,
) -> None:
    html_file = cwd / f"..{permalink}.html"
    html_file.write_text(
        f"""---
layout: default
permalink: {permalink}
title: "{browser_title}"
nav: Blog
feed:
  url: {permalink}
  title: "{feed_title}"
---
<div class="blog-subtitle">
{subtitle}
</div>
^^^
{top_content}
<div class="blog-subpage-title">{title}:</div>
{main_content}""",
        encoding="utf-8",
    )


def generate_comments(comments: list[dict], post: bool, flatten: bool) -> str:
    content = f"""
{create_comments_liquid_filter(comments)}
{{% include comments.html
        comments=comments
        top=false
        context=true
        post={post}
        flatten={flatten}
%}}"""
    return content


def generate_feed(
    config: dict,
    post_id_map: dict,
    comments: list[dict],
    title: str,
    permalink: str,
    entry_info: dict,
    description: str = None,
    author: str = "Charalampos Kardaris",
    update: datetime = None,
    html: dict = None,
) -> None:
    fg = FeedGenerator()

    site_url = config["url"]

    feed_url = f"{site_url}{permalink}.xml"
    actual_url = f"{site_url}{permalink}.html"

    fg.id(feed_url)
    fg.title(title)
    fg.author(name=author)
    fg.language("en")
    fg.link(href=feed_url, rel="self")
    fg.link(href=actual_url, rel="alternate")
    if description:
        fg.description(description)

    # Newest first
    comments.sort(key=lambda c: parse_date(c["date"]), reverse=False)

    update_time = parse_date(comments[0]["date"]) if comments else update
    fg.updated(update_time)

    if comments:
        for comment in comments:
            entry = fg.add_entry()

            entry_name = f" by {comment['name']}" if entry_info["name"] else ""
            entry_post = (
                f" on '{post_id_map[comment['post']]['title']}'"
                if entry_info["post"]
                else ""
            )
            entry.title(f"Comment #{comment['id']}{entry_name}{entry_post}")
            entry.author(name=comment["name"])
            entry.content(markdown_to_html(comment["comment"]), type="html")

            entry_url = comment_url(site_url, comment)
            entry.id(entry_url)
            entry.link(href=entry_url)

            entry_date = parse_date(comment["date"])
            entry.published(entry_date)
            entry.updated(entry_date)
    else:
        # Create one single entry, so that the feed is valid.
        entry = fg.add_entry()
        entry.title("No comments yet.")
        entry.id(actual_url)
        entry.link(href=actual_url)
        entry.published(update_time)
        entry.updated(update_time)

    # Create atom feed file.
    atom_file = cwd / f"..{permalink}.xml"
    atom_file.parent.mkdir(parents=True, exist_ok=True)
    fg.atom_file(atom_file, pretty=True)

    # Add jekyll front matter, so that I can use site variables.
    content = atom_file.read_text(encoding="utf-8")
    atom_file.write_text(
        f"""---
---
{content}""",
        encoding="utf-8",
    )

    # Create contents of the corresponding HTML page.
    if html:
        generated_comments = generate_comments(
            [x for x in comments if x != html["comments"].get("exclude", None)],
            str(entry_info["post"]).lower(),
            html["comments"]["flatten"],
        )
        create_blog_page(
            permalink=permalink,
            browser_title=html["browser_title"],
            title=html["title"],
            feed_title=title,
            top_content=html.get("top_content", ""),
            subtitle=f"""subscribe to this <a href="{permalink}.xml">feed</a>""",
            main_content=f"""
{html.get("title_actions", "")}
{generated_comments}""",
        )


def is_reply(comment: dict, reply: dict, direct_only: bool) -> bool:
    if direct_only:
        return reply["ancestors"] and comment["id"] == reply["ancestors"][-1]
    else:
        return comment["id"] in reply["ancestors"]


def generate_user_actions(user: str, nav: str) -> str:
    actions = ["comments", "threads", "replies"]
    assert nav in actions
    result = ""
    for action in actions:
        result += f"""<a class="action {"nav-selected" if action == nav else ""}" href="/blog/user/{user}/{action}">{action}</a>\n"""
    return result


def generate_comment_actions(comment: str, nav: str) -> str:
    actions = ["thread", "replies"]
    assert nav in actions
    result = ""
    for action in actions:
        result += f"""<a class="action {"nav-selected" if action == nav else ""}" href="/blog/comment/{comment}/{action}">{action}</a>\n"""
    return result


def main() -> None:
    config, comments, post_id_map = load_yaml_files()

    # All users with at least one comment.
    users = list(set([comment["name"] for comment in comments]))

    for user in users:
        comments_by_user = [x for x in comments if x["name"] == user]
        assert comments_by_user
        generate_feed(
            config,
            post_id_map,
            comments_by_user,
            title=f"Comments by {user}",
            permalink=f"/blog/user/{user}/comments",
            entry_info={"name": False, "post": True},
            author=user,
            html={
                "browser_title": f"{user} - comments",
                "title": user,
                "title_actions": generate_user_actions(user, "comments"),
                "comments": {
                    "flatten": "true",
                },
            },
        )

        comment_dates = [x["date"] for x in comments_by_user]
        comment_dates.sort()
        last_comment_date = comment_dates[-1]

        threads = []
        replies = []
        for comment in comments_by_user:
            threads += [comment] + [
                r for r in comments if is_reply(comment, r, direct_only=False)
            ]
            replies += [r for r in comments if is_reply(comment, r, direct_only=True)]

        comment_ids_by_user = [x["id"] for x in comments_by_user]

        generate_feed(
            config,
            post_id_map,
            threads,
            title=f"Threads by {user}",
            permalink=f"/blog/user/{user}/threads",
            entry_info={"name": True, "post": True},
            author=user,
            html={
                "browser_title": f"{user} - threads",
                "title": user,
                "title_actions": generate_user_actions(user, "threads"),
                "comments": {
                    "flatten": "false",
                },
            },
        )
        generate_feed(
            config,
            post_id_map,
            replies,
            title=f"Replies to {user}",
            permalink=f"/blog/user/{user}/replies",
            entry_info={"name": True, "post": True},
            author=user,
            update=parse_date(last_comment_date),
            html={
                "browser_title": f"{user} - replies",
                "title": user,
                "title_actions": generate_user_actions(user, "replies"),
                "comments": {
                    "flatten": "true",
                },
            },
        )

        create_redirect_page(f"/blog/user/{user}", f"/blog/user/{user}/comments")

    for comment in comments:
        thread = [comment] + [
            r for r in comments if is_reply(comment, r, direct_only=False)
        ]
        replies = [r for r in comments if is_reply(comment, r, direct_only=True)]

        generate_feed(
            config,
            post_id_map,
            thread,
            title=f"""Thread of comment #{comment["id"]} on '{post_id_map[comment["post"]]["title"]}'""",
            permalink=f"/blog/comment/{comment['id']}/thread",
            entry_info={"name": True, "post": False},
            author=comment["name"],
            description=markdown_to_html(comment["comment"]),
            html={
                "browser_title": f"Comment #{comment['id']} - thread",
                "top_content": generate_comments(
                    [comment],
                    post="true",
                    flatten="true",
                ),
                "title": "comments",
                "title_actions": generate_comment_actions(comment["id"], "thread"),
                "comments": {
                    "flatten": "false",
                    "exclude": comment,
                },
            },
        )

        generate_feed(
            config,
            post_id_map,
            replies,
            title=f"""Replies to comment #{comment["id"]} on '{post_id_map[comment["post"]]["title"]}'""",
            permalink=f"/blog/comment/{comment['id']}/replies",
            entry_info={"name": True, "post": False},
            author=comment["name"],
            description=markdown_to_html(comment["comment"]),
            update=parse_date(comment["date"]),
            html={
                "browser_title": f"Comment #{comment['id']} - replies",
                "top_content": generate_comments(
                    [comment],
                    post="true",
                    flatten="true",
                ),
                "title": "comments",
                "title_actions": generate_comment_actions(comment["id"], "replies"),
                "comments": {
                    "flatten": "true",
                },
            },
        )
        create_redirect_page(
            f"/blog/comment/{comment['id']}", f"/blog/comment/{comment['id']}/thread"
        )

    posts = list(set(x["post"] for x in comments))
    for post, data in post_id_map.items():
        generate_feed(
            config,
            post_id_map,
            [comment for comment in comments if comment["post"] == post],
            title=f"Comments on '{data['title']}'",
            permalink=f"{post}/comments",
            entry_info={"name": True, "post": False},
            update=data["date"],
            html={
                "browser_title": f"{data['title']} - Comments",
                "title": f"""Comments on <a href="{post}">{data["title"]}</a>""",
                "comments": {
                    "flatten": "false",
                },
            },
        )


if __name__ == "__main__":
    main()
