---
layout: post
title: "The P in PGP isn’t for pain: encrypting emails in the browser"
tags: programming security website
description: How to receive encrypted messages via emails with openPGP.js
---

In my previous post, I described how I implemented an asynchronous, [email-based comment system]({%
post_url 2026-01-22-my-comments-run-on-email %}) for this blog that runs without a true backend.
Every comment is an email sent to a specified address.
After each email is processed, all information is stored publicly in a GitHub repository.

One of the limitations of such a system is user authentication.
Each user needs to send a password alongside each comment that serves to authenticate the user
against their email.
This is needed because *email spoofing* is a thing and identity theft is not a joke; even if the
stakes are low in the context of blog comments.

In that previous post, I acknowledged that sending a password in plain text via email is not best
practice and I encouraged the usage of encryption.
For this purpose, I provided a [public PGP key](/{{ site.pgp }}) that can be used to encrypt any
email and can only be decrypted by me, the owner of the secret key.

# Problem

The problem with this suggestion is that, even though it's technically sound and legitimate, it is
not straightforward to set up.
Many email clients do not even support PGP encryption and, dare I say, even most technical people do
not have it set up by default.
For non-technical users, configuring everything properly would certainly be a test of computer
literacy.

This is not good enough, and certainly not welcoming or inclusive.

# Solution

Shortly after I published the first version of the comment system I came up with a question.

> I already have a public PGP key published and ready to be used.
> Is there a way to encrypt the comment payload on the browser, including the password and all other
> data?

I wouldn't be writing this post if the answer was negative.

After a quick web search, I came across [openPGP.js](https://openpgpjs.org/), a JavaScript library
maintained by the [Proton team](https://proton.me/).
The goal of the library is to *"bypass the PGP installation requirement in every machine"*.
Just perfect for my use case.

I quickly set everything up.
I downloaded the JavaScript library files at the root of my website and created a couple of helper
functions.
The first to load the library on-demand to avoid unnecessary network transactions and the
second to produce a PGP encrypted message from a plain text string input.

``` js
function loadScript(src) {
    return new Promise((resolve, reject) => {
        // Prevent loading the same script twice
        if (document.querySelector(`script[src="${src}"]`)) {
            resolve();
            return;
        }

        const script = document.createElement('script');
        script.src = src;
        script.async = true;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

async function encrypt(message) {
    const publicKeyArmored = `{% raw %}{% include pgp-public-key.txt %}{% endraw %}`.trim();

    await loadScript('/openpgp.min.js');

    return await window.openpgp.encrypt({
        message: await openpgp.createMessage({ text: message }),
        encryptionKeys: await window.openpgp.readKey({ armoredKey: publicKeyArmored })
    });
}
```

It's simple.
And it works.

> **Note:** The comment encryption functionality is not available if *JavaScript* is disabled on the
> client.

For example, if you were to write a comment for this post using the *comment form* and provided the
following data:
```
username: test_user
password: test_password
comment: Test comment.
```
the email to be sent would be pre-filled with the following body:
```
Your comment has been encrypted and is ready to be submitted.
...

-----BEGIN PGP MESSAGE-----

wV4Dyk92dA2JWC4SAQdAFgNHlb6Q7nAgovzVgUnB5CTOKBWSlXxSoIOzLUQl
Zm4wBdsLdUROxNS0xcTyja4iq9QUsSazv18DYbmRd2Lix3XoL4zDrQVOPVw6
ZGlkeDhi0qEByCityS59xWSuREVqgS4tpPlZg8Lz5Go6D2nSBu+1iTXw2dy6
L9eL5NZMoFhYUqocGukxBlEcHY6j1U+3Lstvc5dZPl+u7+Zh32uTzTo8CC05
doKNwH5AP9ybHk7nr2vVLdrede6vLCIAwGTK9fVYq2V1udXfSPNCESSeunh1
68qEaAA81mjCbSSfcB/RznpL8/nOLLWDXlXxfMPlYV8/+Q==
=k2VX
-----END PGP MESSAGE-----
```
Your comment data (username, password, message, etc.) is automatically encrypted without any
need for manual intervention.

# Conclusion

Based on the above proof of concept, I can say that, even without operating a "proper" backend
server, it is still possible to guarantee a reasonable level of security.
And you can do so without requiring any complicated setup on the user side.

To my eyes, this is a win for secure communication when email is used as the medium.
Do you agree?
