async function sha256(str) {
    const data = new TextEncoder().encode(str);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    return [...new Uint8Array(hashBuffer)]
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");
}

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
    const publicKeyArmored = `{% include pgp-public-key.txt %}`.trim();

    await loadScript('/openpgp.min.js');

    return await window.openpgp.encrypt({
        message: await openpgp.createMessage({ text: message }),
        encryptionKeys: await window.openpgp.readKey({ armoredKey: publicKeyArmored })
    });
}

async function sendEmail(replyId = "") {
    const form = document.getElementById(`comment-form-${replyId}`);
    if (!form.checkValidity()) {
        return;
    }
    const username = document.getElementById(`username-${replyId}`).value.trim();
    const comment = document.getElementById(`comment-input-${replyId}`).value.trim();
    const password = await sha256(document.getElementById(`password-${replyId}`).value.trim());

    const subject = "Comment: {{ page.title }}";
    let data = `post: {{ page.id }}`;
    data += replyId ? `\nrepliesTo: ${replyId}` : "";
    data += `
name: ${username}
password: ${password}
comment: |-
${comment.split('\n').map(line => "  " + line).join('\n')}
`;
    const encryptedData = await encrypt(data);

    let body = `Your comment has been encrypted and is ready to be submitted.
Please do not edit the following lines.

${encryptedData}
`;

    const mailto = "mailto:{{ site.mailto }}?subject=" + encodeURIComponent(subject) + "&Whatever&body=" + encodeURIComponent(body);
    window.open(mailto, "_blank");
}

// Register on-click callback for the comment submit buttons.
document.querySelectorAll(".comment-submit").forEach(el => {
    el.addEventListener("click", e => {
        sendEmail(e.currentTarget.id.replace("comment-submit-", ""))
    });
})
