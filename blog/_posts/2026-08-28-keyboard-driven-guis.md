---
layout: post
title: GUIs should be fully keyboard-driven
tags: programming
description: GUI applications should be fully driven by the keyboard using shortcuts
---

Last week I came across a [post on *Hacker
News*](https://sockpuppet.org/blog/2026/08/20/stop-making-tuis/) that encouraged application
developers to stop making terminal user interfaces[^1]
(a.k.a. TUIs) and instead focus on graphical user interfaces (a.k.a. GUIs).
The post reached the HN front page and sparked a lively debate in the
[comments](https://news.ycombinator.com/item?id=49384210) section.

[^1]: Or alternatively [text-based user
    interfaces](https://en.wikipedia.org/wiki/Text-based_user_interface).

I think there is merit in both sides of the debate.
On one hand, I understand the GUI-positive arguments of the post author.
In theory, the capabilities of GUI application frameworks are a superset of the capabilities of
their TUI counterparts, so they should be preferred.
On the other hand, as a heavy *terminal user*, I *also* greatly appreciate all TUIs that allow me to
"stay" in the terminal and fulfill all my needs.

But I want to oppose a recurring argument in favor of TUIs that in my opinion does not have a solid
foundation[^2].
To paraphrase various commenters:

[^2]: The original post author mentions this as well.

> TUIs should be preferred because they are keyboard-driven.

While it's true that if you randomly pick a GUI and a TUI application, the latter is more probable
to be fully keyboard-driven, this does not tip the scale in favor of developing TUIs over GUIs[^3].
What it does is highlight the inadequacies of keyboard navigation in many GUI applications.

[^3]: There are other more compelling arguments towards tipping that scale, for example ease of
    portability.

There is nothing preventing a GUI from being fully keyboard-driven[^4] just like — or even better
than — a TUI.
In fact, many GUI framework application guidelines explicitly encourage GUI application developers
to provide support for keyboard-driven navigation that covers the whole functionality of the
application.

[^4]: Of course, the dexterity achieved via mouse is still preferred — or even required — for some
    tasks.

For example, the GNOME Human Interface Guidelines state that [*just as it should be possible to perform every
action with a pointing device, every action should also be possible with the
keyboard*](https://developer.gnome.org/hig/guidelines/keyboard.html#:~:text=Just%20as%20it%20should%20be%20possible%20to%20perform%20every%20action%20with%20a%20pointing%20device%2C%20every%20action%20should%20also%20be%20possible%20with%20the%20keyboard)
and that [*it should be possible to move around and interact with every part of your user interface
using the
keyboard*](https://developer.gnome.org/hig/guidelines/keyboard.html#:~:text=It%20should%20be%20possible%20to%20move%20around%20and%20interact%20with%20every%20part%20of%20your%20user%20interface%20using%20the%20keyboard).

This resonates with me as a user.
Being able to intuitively — and predictably — navigate around a GUI application with only my
keyboard gives me more incentive to choose it compared to its alternatives.

Knowing that, and when wearing my developer hat, I have to make sure that my
applications are keyboard-friendly.
For my first ever GUI application, [Klisi](https://gitlab.com/ckardaris/klisi), I invested some time
to implement keyboard shortcuts targeting the whole range of available actions.

Keyboard navigation is not that hard to achieve in most cases and results in an overall better user
experience.
It is not a matter of feasibility, but a matter of will on the application developer's part.

The takeaway is simple.
Do not compromise on the user experience you provide with your application.
Strive to make it as intuitive as possible.
To that end, enabling full keyboard navigation should not be ignored.
