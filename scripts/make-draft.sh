#!/usr/bin/env bash

file="blog/_drafts/$(date +%Y-%m-%d)-$1.md"
touch "$file"
cat << EOF > "$file"
---
layout: post
title:
tags:
---
EOF

touch _layouts/posts.html
vim "$file"
