async function sendEmail(replyId = "") {
    const form = document.getElementById(`comment-form-${replyId}`);
    if (!form.checkValidity()) {
        return;
    }
    const username = document.getElementById(`username-${replyId}`).value.trim();
    const comment = document.getElementById(`comment-input-${replyId}`).value.trim();
    const password = document.getElementById(`password-${replyId}`).value.trim();

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

    const body = `Your comment has been encrypted and is ready to be submitted.
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
