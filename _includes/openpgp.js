async function encrypt(message) {
    const publicKeyArmored = `{% include pgp-public-key.txt %}`.trim();

    await loadScript('/openpgp.min.js');

    return await window.openpgp.encrypt({
        message: await openpgp.createMessage({ text: message }),
        encryptionKeys: await window.openpgp.readKey({ armoredKey: publicKeyArmored })
    });
}
