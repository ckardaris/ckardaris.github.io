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
