---
layout: post
title: My comments run on email
tags: programming website
description: My website comments setup using email as the backend.
---

Not all blogs support commenting.
Initially, I considered doing without them.
There are many places where one may share an article or blog post and start a discussion.
I frequent [*Hacker News*](https://news.ycombinator.com/news)[^1] myself and I really appreciate the
breadth of opinions in some of the discussions.
Discussion can happen in other *spaces* as well, like *Reddit*, *LinkedIn*[^2] and many more.

[^1]: The user interface (UI) of my comments is *heavily* inspired by HN comments.
[^2]: Even if too *corporatey* most of the time.

Despite the abundance of such *spaces*, where discussions can happen, I think it is convenient and
fitting --- especially for blog posts --- when the actual post and the readers' comments live
together.

With that in mind, and feeling the urge to [hack a little more on my website]({% post_url
2026-01-10-techrastination %}), during the past weekend I set out to add support for comments in
this blog.

Doing so in a static blog poses a big **challenge**.
There is no actual server running that can handle requests and process data.
That means that you do not have the necessary infrastructure for user accounts.
The readers cannot log in and send their comments and there is no straightforward way to take those
comments and automatically post them online.

Another method is therefore needed to receive the comments and provide them as input to the static
site generator, in my case [jekyll](https://jekyllrb.com/).

One of the most frequently used solutions to this problem is [giscus](https://giscus.app/).
*giscus* is utilizing *GitHub* discussions to store comments for the different blog posts and can be
configured to automatically update your website when a new comment is created.

This approach is very appealing, but it has one disadvantage in my opinion.
The person who wants to comment needs to have a *GitHub* account.
This can be a blocker for non-technical people.

I wanted to use a different approach and I also wanted to make commenting accessible to as many
people as possible.
After some thinking I decided to use the most common technology I could think of.

**Email.**

Almost everyone using the internet has an email address.
By basing my comment system on email, I can make it accessible to a wide range of people.

The fact that every email address is unique allows to implement a kind of primitive authentication
setup.
I am saying primitive, because email is not secure by default, and by extension neither is any
system built on top of it.

It goes without saying that this system could never be used in production in security-sensitive
environments. That said, crazier things have happened.

# Technical overview

At this point, it would be useful to go in a little more detail.
If you are not interested in the technical aspects of the comment system implementation you can skip
this section and go straight to the [end](#final-thoughts). You will miss all the fun, though.

So, how does it all work?

## Requirements

Before implementing the comment system, I drafted some requirements:

1. All comments should be displayed with a visible *name*[^3] selected by the commenter and the
   *date* they were made.
2. A commenter should be able to change their visible *name*.
3. A malicious actor should not be able[^4] to assume the identity of a commenter.
4. Sending a comment should be as easy as possible and the comment system should be functional with
   *JavaScript* disabled.
5. Comment replies should be supported and presented in a nested tree structure, which should
   support collapse and expansion of comment sub-trees.

[^3]: Or *nickname*.
[^4]: Although, you can never be 100% secure.

## Data

The comment system is based on email, so it is logical that you send a comment by sending an email.
Every comment email contains all necessary information, so that the comment can be presented
correctly.
I decided to send the information in the *YAML* format, since *jekyll* is *YAML*-friendly.
Additionally, *YAML* compared to *JSON* can be more readable for multi-line data, like comments, so
it made it more fitting for this use case.

Every comment email sends in its body the following information.
``` yaml
post:
name:
password:
repliesTo:
comment: |-
```

Sending passwords in plain text is almost always frowned upon.
But I believe this situation deserves some leeway.

- The data transferred is not sensitive and proper care is taken to ensure confidentiality.
- This is an educational project with no hard security requirements.
- A password is good to be used as a measure against [sender address
  spoofing](https://en.wikipedia.org/wiki/Email_spoofing).
- Email can always be hardened by using [*PGP
  encryption*](https://en.wikipedia.org/wiki/Pretty_Good_Privacy)[^5]:

[^5]: Here is the [PGP public key](/{{site.pgp}}).

Upon receiving a comment email, some additional information can be obtained: `email_address` and `date`.

## Implementation

Let's see how we can satisfy the system requirements with these data.

> All comments should be displayed with a visible name selected by the commenter and the
   *date* they were made.

For this we use the `name` and `date` information from the actual comment email.

> A commenter should be able to change their visible name.<br>
> A malicious actor should not be able to easily assume the identity of a commenter.

All information needed to generate this website is publicly stored in a *GitHub* repository.
This means that any personal information needs to be properly stored.

For each received comment email a [*SHA256*](https://en.wikipedia.org/wiki/SHA-2) message digest
(*hash*) is computed using the `email_address` and a
[*salt*](https://en.wikipedia.org/wiki/Salt_%28cryptography%29)[^7].

[^7]: Storing message digests of *salted* data guarantees that, even though all stored data is
    publicly available, it is not possible to find out which email addresses are stored and what
    *name* each email is using.

To check *name* availability, all *email hashes* that are **different** from the current one are
gathered and their linked *name* is compared to the requested one.
If no matches are found the `name` can be used.

An additional message digest is computed for the authentication of the commenter using the
`email_address`, the `password` and the *salt*.

This *authentication hash* is compared against the *authentication hash* of one of previous comment
emails that share the **same** *email hash*[^8].

[^8]: If any, the rest of the comments from the same email address have the same *authentication
    hash*.

In the event of any error, the commenter is informed with a response email.

>  Sending a comment should be as easy as possible and the comment system should be functional with
   *JavaScript* disabled.

Commenters with *JavaScript* enabled can enjoy a streamlined user experience (UX).
Clicking on <u>add comment</u> or <u>reply</u> presents them with an *HTML* form with three input
fields: *name*, *password* and *comment*.
After filling them and clicking the *send* button, their preferred email client is launched and the
message is pre-filled for them and ready to be sent.

Commenters with *JavaScript* disabled still get a pre-filled email message, but they have to fill
the necessary information, while making sure to not break the formatting of the data.

Writing a comment using the *HTML* form with *JavaScript* enabled has two benefits:

1. Browsers are able to save the *name* and *password* fields for the commenter and pre-fill them in
   the future.
2. The password can be hashed in the email body. This does not improve security, but
   protects against curious eyes.

>  Comment replies should be supported and presented in a nested tree structure, which should
   support collapse and expansion of comment sub-trees.

Using the `repliesTo` field of the comment email[^9], a tree hierarchy of messages is created.
This hierarchy is used to sort the comments properly and to create the necessary logic to collapse
and expand the respective sub-trees of comments.

[^9]: Root messages, of course, do not set this value.

## Synchronization

We are close to the end, but I have so far failed to mention one basic characteristic of the comment
system.
And this concerns its responsiveness, or lack thereof.

After receiving a comment email, there is, as of now, no automation set up to process the email and
post it on the blog.
Posting each comment requires manual intervention.
This makes the discussion asynchronous.
I think that this is not a big issue and does not look out of place considering the static nature of
the website.

Nevertheless, I leave the door open to automation.
Interacting with email is scriptable with programs like [*msmtp*](https://marlam.de/msmtp/)
and [*isync*](https://isync.sourceforge.io/).
In the unlikely but welcome scenario that the volume of the received comment emails is too large to
handle manually, another weekend hacking project could automate the whole process.

# Final thoughts

Creating a comment system based on email has been a worthwhile experience.
I revisited some long-studied concepts and learned new ones.
It was a good exercise in balancing trade-offs which I believe is one of the most important aspects
of designing a system.

The final result leaves me satisfied, while also leaving room for improvements in the future.

And after all this work, I can finally say
> Let me know what you think in the comments.
