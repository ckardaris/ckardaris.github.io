async function changePassword() {
    const oldPassword = document.getElementById("password-old").value.trim();
    const newPassword = document.getElementById("password-new").value.trim();

    const subject = "Change password";
    let data = `old_password: ${oldPassword}
new_password: ${newPassword}
`;
    const encryptedData = await encrypt(data);

    const body = `Your request has been encrypted and is ready to be submitted.
Please do not edit the following lines.

${encryptedData}
`;
    const mailto = "mailto:{{ site.mailto }}?subject=" + encodeURIComponent(subject) + "&Whatever&body=" + encodeURIComponent(body);
    window.open(mailto, "_blank");
}

async function resetPassword() {
    const subject = "Reset password";
    const body = `Your request is ready to be submitted.

You will receive a reply with your new password.
It is advised to change it immediately, by visiting {{ site.url | append: "/blog/account"}}.
`;
    const mailto = "mailto:{{ site.mailto }}?subject=" + encodeURIComponent(subject) + "&Whatever&body=" + encodeURIComponent(body);
    window.open(mailto, "_blank");
}

// Register on-click callback for the password change button.
const passwordChange = document.getElementById("password-change-button");
if (passwordChange) {
    passwordChange.addEventListener("click", changePassword);
}

// Register on-click callback for the password reset button.
const passwordReset = document.getElementById("password-reset");
if (passwordReset) {
    passwordReset.addEventListener("click", resetPassword);
}
