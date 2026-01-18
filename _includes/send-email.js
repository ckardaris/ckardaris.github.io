function sendEmail(replyId = "") {
    const form = document.getElementById(`comment-form-${replyId}`);
    if (!form.checkValidity()) {
        return;
    }
    const username = document.getElementById(`username-${replyId}`).value.trim();
    const comment = document.getElementById(`comment-input-${replyId}`).value.trim();

    const subject = "Comment: {{ page.title }}";
    let body = `post: {{ page.id }}`;
    body += replyId ? `\nrepliesTo: ${replyId}` : "";
    body += `
name: ${username}
comment: |-
${comment.split('\n').map(line => "  " + line).join('\n')}
`;
    const mailto = "mailto:{{ site.mailto }}?subject=" + encodeURIComponent(subject) + "&Whatever&body=" + encodeURIComponent(body);
    window.open(mailto, "_blank");
}
