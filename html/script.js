const radio = document.getElementById('radio');
const powerBtn = document.getElementById('power-btn');
const freqInput = document.getElementById('freq-input');
const joinBtn = document.getElementById('join-btn');
const currentFreqDisplay = document.getElementById('current-freq');
const statusText = document.getElementById('status-text');
const statusBar = document.querySelector('.status-bar');

let isOn = false;
let currentFreq = null;

// Listen for NUI messages
window.addEventListener('message', function (event) {
    if (event.data.type === "open") {
        radio.style.display = "flex";
        setTimeout(() => {
            radio.classList.add('radio-slide-in');
        }, 10);
    } else if (event.data.type === "close") {
        radio.classList.remove('radio-slide-in');
        setTimeout(() => {
            radio.style.display = "none";
        }, 500);
    }
});

// Close on ESC
document.onkeyup = function (data) {
    if (data.which == 27) {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }
};

// Power Button
powerBtn.addEventListener('click', () => {
    isOn = !isOn;
    powerBtn.classList.toggle('active');

    if (isOn) {
        currentFreqDisplay.textContent = currentFreq ? currentFreq : "WAIT";
        statusBar.classList.add('active');
        statusText.textContent = "Powered On";
        // Play sound effect here
    } else {
        currentFreqDisplay.textContent = "OFF";
        statusBar.classList.remove('active');
        statusText.textContent = "Disconnected";
        leaveRadio();
    }
});

// Join Frequency
joinBtn.addEventListener('click', () => {
    if (!isOn) return;

    const freq = parseFloat(freqInput.value);
    if (freq > 0 && freq < 1000) {
        currentFreq = freq;
        currentFreqDisplay.textContent = freq.toFixed(1);
        statusText.textContent = `Connected: ${freq} MHz`;

        fetch(`https://${GetParentResourceName()}/joinRadio`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ channel: freq })
        });
    } else {
        statusText.textContent = "Invalid Frequency";
    }
});

// Volume Slider
const volumeSlider = document.getElementById('volume-slider');
volumeSlider.addEventListener('input', (e) => {
    const volume = e.target.value;
    fetch(`https://${GetParentResourceName()}/setVolume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ volume: volume })
    });
});


function setPreset(num) {
    if (!isOn) return;
    // Example presets
    const presets = { 1: 91.1, 2: 100.5, 3: 450.0 };
    if (presets[num]) {
        freqInput.value = presets[num];
        joinBtn.click();
    }
}
