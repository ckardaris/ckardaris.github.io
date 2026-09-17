---
layout: default
title: Repository
permalink: /flatpak/
---
<div id="flatpak-repo-icon">
{% include assets/flatpakrepo-icon.svg %}
</div>


This is my personal flatpak repository. Here you can find and install flatpak packages of my
applications.

# Setup

<details>
  <summary>Instructions</summary>
  <div markdown="1">
1. Install flatpak on your machine by following the [instructions](https://flathub.org/en/setup) for your distribution.
2. Add this flatpak repository.<br>
```
flatpak remote-add --user --if-not-exists ckardaris.com {{ site.url }}/flatpak/ckardaris.com.flatpakrepo
```
3. Install applications.<br>
```
flatpak install --user ckardaris.com <app-id>
```
  </div>
</details>

# Applications

<div id="flatpak-list">
 {% for item in site.data.flatpaks %}
   {% assign application = item[1] %}
   {% assign svg = "assets/" | append: application.svg %}
   <a href="/flatpak/applications/{{application.id}}">
       <div class="flatpak-list-item">
           {% include {{ svg }} %}
           <div>
             <div class="flatpak-item-title">{{ application.name }}</div>
             <div>{{ application.summary }}</div>
           </div>
       </div>
   </a>
 {% endfor %}
<div>

{% include script.html script="copy.js" %}
