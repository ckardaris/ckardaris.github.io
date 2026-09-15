---
layout: default
title: Charalampos Kardaris
permalink: /
description: Hi, I am Charalampos Kardaris and this is my website.
home: true
---
<div id="home-page-links">
{%- for path in site.header_pages -%}
  {%- assign nav_page = site.pages | where: "path", path | first -%}
    <div class="home-page-link">
        <a href="{{ nav_page.url | relative_url }}">{{ nav_page.title }}</a>
    </div>
{%- endfor -%}
<div>
