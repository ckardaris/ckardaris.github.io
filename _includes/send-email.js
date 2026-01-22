async function sha256(str) {
    const data = new TextEncoder().encode(str);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    return [...new Uint8Array(hashBuffer)]
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");
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
    let body = `post: {{ page.id }}`;
    body += replyId ? `\nrepliesTo: ${replyId}` : "";
    body += `
name: ${username}
password: ${password}
comment: |-
${comment.split('\n').map(line => "  " + line).join('\n')}
`;
    const mailto = "mailto:{{ site.mailto }}?subject=" + encodeURIComponent(subject) + "&Whatever&body=" + encodeURIComponent(body);
    window.open(mailto, "_blank");
}
