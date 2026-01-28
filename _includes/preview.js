document.querySelectorAll('.preview-input').forEach(el => {
    const id = el.id.replace(/^preview-/, '');
    const textarea = document.getElementById(`comment-input-${id}`);
    const markdown = document.getElementById(`comment-markdown-${id}`);
    el.addEventListener('change', async function() {
        if (this.checked) {

            await loadScript('/markdown-it.min.js');

            const md = window.markdownit({ html: true });

            textarea.style.display = "none";
            markdown.style.display = "block";
            markdown.innerHTML = md.render(textarea.value);
        } else {
            textarea.style.display = "block";
            markdown.style.display = "none";
        }
    })
});
