---
layout: post
title: New address, new adventures
tags: website
description: This website has migrated to ckardaris.com
---

I had been thinking of buying my own domain to host this website for a while.
I was always putting it off, since it was not a priority or a strict necessity.
But, lately, I reached a tipping point.

I have been working on a side project that requires setting an application identifier.
From the beginning I knew that I wanted to go with `com.ckardaris.<Appname>` and not share "naming
custody" with GitHub.
You don't *really* need to own a domain to use it as part of an application identifier, but it makes
verification with some platforms possible.

So, I bit the bullet and moved forward with my plans.

`ckardaris.com` is now **live**.

The whole process was quite quick. It took a couple hours reading the required documentation and
setting everything up.

I registered the domain via [porkbun](https://porkbun.com/).

I [verified the new
domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/verifying-your-custom-domain-for-github-pages)
for GitHub Pages to avoid any future surprises and added any additional DNS records needed.

~~I created a second static website repository on GitHub and pushed the existing repository to it.
As the first order of business (i.e. first commit) I made sure to fix any "stale" links pointing to
the old `ckardaris.github.io` domain to now point to the new one.~~

~~Finally, I edited the old static site to redirect to the new one automatically and that was
all[^1].~~

``` html
  <script>
    window.location.href = "https://ckardaris.com" + window.location.pathname + window.location.search + window.location.hash;
  </script>
  <noscript>
    <meta http-equiv="refresh" content="0; url=https://ckardaris.com{% raw %}{{ page.url }}{% endraw %}">
  </noscript>
```

*UPDATE*: It turns out I did not read the GitHub Pages documentation carefully enough.
Creating the second repository and the manual redirects were not needed.
By setting the custom domain in the original repository, GitHub handles the redirects from the
default domain (i.e. `ckardaris.github.io`), while properly returning the `301` status code in the
process.

[^1]: Reading online I got the understanding that a proper redirect emitting the `301` status code
    would be preferable in order to preserve any search engine ranking that I had. But, honestly, I
    don't think that will prove to be much of an issue.

This was my first ever domain purchase and I have to say everything went quite smoothly, so I am
satisfied.

That's all for now. Watch this space for my side project update.

See you soon.
