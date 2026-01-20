document.querySelectorAll('.eye-input').forEach(el => {
    el.addEventListener('change', function() {
        this.previousElementSibling.type = this.checked ? 'text' : 'password';
    })
});
