#!/usr/bin/env bash

drafts="blog/_drafts"

mkdir -p "$drafts"

file="$drafts/$(date +%Y-%m-%d)-$1.md"
touch "$file"
cat << EOF > "$file"
---
layout: post
title:
tags:
description:
---
EOF

vim "$file"
