function copyToClipboard(element) {
    const temp = document.createElement('textarea');
    temp.value = document.querySelector(element).textContent;

    document.body.appendChild(temp);

    temp.select();

    document.execCommand('copy');
    document.body.removeChild(temp);

    alert('Copied to clipboard!');
}