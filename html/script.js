const radio = document.getElementById('radio');
const powerBtn = document.getElementById('power-btn');
const freqInput = document.getElementById('freq-input');
const joinBtn = document.getElementById('join-btn');
const currentFreqDisplay = document.getElementById('current-freq');
const statusText = document.getElementById('status-text');
const statusBar = document.querySelector('.status-bar');
const volumeSlider = document.getElementById('volume-slider');
const presetButtons = document.querySelectorAll('.btn-preset');

let isOn = false;
let currentFreq = null;
let minFreq = 1.0;
let maxFreq = 999;
let presets = [91.1, 100.5, 450.0];

async function postNui(endpoint, payload = {}) {
    const response = await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    });

    try {
        return await response.json();
    } catch (_) {
        return { ok: true };
    }
}

function updateStatus(message, isError = false) {
    statusText.textContent = message;
    statusText.style.color = isError ? '#ff6868' : '';
}

function setPowerState(nextState) {
    isOn = nextState;
    powerBtn.classList.toggle('active', isOn);

    if (isOn) {
        currentFreqDisplay.textContent = currentFreq ? currentFreq.toFixed(1) : 'WAIT';
        statusBar.classList.add('active');
        updateStatus(currentFreq ? `Connected: ${currentFreq.toFixed(1)} MHz` : 'Powered On');
        return;
    }

    currentFreqDisplay.textContent = 'OFF';
    statusBar.classList.remove('active');
    updateStatus('Disconnected');
}

// Listen for NUI messages
window.addEventListener('message', function (event) {
    if (event.data.type === "open") {
        maxFreq = Number(event.data.maxFrequency ?? 999);
        minFreq = Number(event.data.minFrequency ?? 1.0);
        presets = Array.isArray(event.data.presets) ? event.data.presets : presets;
        currentFreq = event.data.currentChannel !== undefined && event.data.currentChannel !== null
            ? Number(event.data.currentChannel)
            : null;

        freqInput.setAttribute('min', minFreq);
        freqInput.setAttribute('max', maxFreq);
        volumeSlider.value = Number(event.data.defaultVolume ?? 50);

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
        postNui('close');
    }
};

// Power Button
powerBtn.addEventListener('click', async () => {
    const nextState = !isOn;
    setPowerState(nextState);

    if (!nextState) {
        await postNui('leaveRadio');
    }
});

// Join Frequency
joinBtn.addEventListener('click', async () => {
    if (!isOn) return;

    const freq = parseFloat(freqInput.value);
    if (!Number.isFinite(freq) || freq < minFreq || freq > maxFreq) {
        updateStatus(`Frequency must be ${minFreq.toFixed(1)}-${maxFreq.toFixed(1)}`, true);
        return;
    }

    const result = await postNui('joinRadio', { channel: freq });
    if (!result?.ok) {
        updateStatus(result?.error || 'Access denied', true);
        return;
    }

    currentFreq = Number(result.channel || freq);
    currentFreqDisplay.textContent = currentFreq.toFixed(1);
    updateStatus(`Connected: ${currentFreq.toFixed(1)} MHz`);
});

// Volume Slider
volumeSlider.addEventListener('input', async (e) => {
    const volume = Number(e.target.value);
    await postNui('setVolume', { volume });
});

freqInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
        joinBtn.click();
    }
});

presetButtons.forEach((button) => {
    button.addEventListener('click', () => {
        if (!isOn) return;
        const index = Number(button.dataset.presetIndex) - 1;
        const preset = presets[index];
        if (Number.isFinite(preset)) {
            freqInput.value = preset;
            joinBtn.click();
        }
    });
});

window.leaveRadio = async function () {
    await postNui('leaveRadio');
    currentFreq = null;
    setPowerState(false);
};

window.setPreset = function (num) {
    const index = Number(num) - 1;
    const preset = presets[index];
    if (Number.isFinite(preset)) {
        freqInput.value = preset;
        joinBtn.click();
    }
};
