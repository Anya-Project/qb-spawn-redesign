document.addEventListener('DOMContentLoaded', () => {
    const terminal = document.getElementById('spawn-terminal');
    const dossier = document.getElementById('location-dossier');
    const locationsList = document.querySelector('.locations-list');
    const confirmBtn = document.getElementById('confirm-spawn');

    let selectedSpawn = null;
    const flavorText = [
        "ZONE: CENTRAL LS | SIGNAL: STRONG", "ZONE: METROPOLITAN | SIGNAL: STABLE",
        "ZONE: NORTHERN SA | SIGNAL: WEAK", "ZONE: SUBURBAN | SIGNAL: AVERAGE",
    ];

    async function post(url, data = {}) {
        try {
            await fetch(`https://qb-spawn/${url}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            });
        } catch (error) { /* Diamkan */ }
    }

    const toggleUI = (show) => {
        if (show) {
            terminal.classList.remove('hidden');
        } else {
            if (terminal) terminal.classList.add('hidden');
            if (dossier) dossier.classList.add('hidden');
        }
    };

    function updateDossier(data) {
        if (!dossier) return;
        dossier.classList.remove('hidden');

        const coords = data.coords || { x: 0, y: 0, z: 0 };
        const setText = (id, value) => {
            const element = document.getElementById(id);
            if (element) element.textContent = value;
        };

        setText('dossier-location-name', data.label || 'NO DATA');
        setText('dossier-district', data.district || 'N/A');
        setText('dossier-coords', `${coords.x.toFixed(2)}, ${coords.y.toFixed(2)}`);
        setText('dossier-elevation', `${coords.z.toFixed(2)} M`);
        setText('dossier-weather', data.weather || 'N/A');
    }

    const createLocationItem = (label, type, name, iconClass) => {
        if (!label || !locationsList) return;
        const item = document.createElement('div');
        item.className = 'location-item';
        
        let infoText = flavorText[Math.floor(Math.random() * flavorText.length)];
        if (type === 'current') infoText = "LAST KNOWN COORDINATES | SIGNAL: UNKNOWN";
        if (type === 'house' || type === 'appartment') infoText = "PRIVATE ACCESS | SIGNAL: ENCRYPTED";

        item.innerHTML = `
            <div class="indicator">></div>
            <i class="fas ${iconClass} icon"></i>
            <div class="location-details">
                <span class="name">${label}</span>
                <span class="info">${infoText}</span>
            </div>
        `;

        item.addEventListener('click', () => {
            document.querySelectorAll('.location-item').forEach(el => el.classList.remove('selected'));
            item.classList.add('selected');
            selectedSpawn = { type, name };
            post('setCam', { posname: name, type: type });
            post('getCoords', { type, name });
            if (confirmBtn) confirmBtn.disabled = false;
        });

        locationsList.appendChild(item);
    };
    
    const resetUI = () => {
        if (locationsList) locationsList.innerHTML = '';
        selectedSpawn = null;
        if (confirmBtn) confirmBtn.disabled = true;
    };

    if (confirmBtn) {
        confirmBtn.addEventListener('click', () => {
            if (!selectedSpawn) return;
            if (selectedSpawn.type === 'appartment') {
                post('chooseAppa', { appType: selectedSpawn.name });
            } else {
                post('spawnplayer', { spawnloc: selectedSpawn.name, typeLoc: selectedSpawn.type });
            }
            toggleUI(false);
        });
    }

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;
        
        const action = data.action;
        const applyColor = (colorCode) => {
            if (colorCode) {
                document.documentElement.style.setProperty('--color-accent', colorCode);
            }
        };

        switch (action) {
            case 'showUi':
                toggleUI(data.status);
                applyColor(data.color); 
                break;
            case 'updateTheme':
                applyColor(data.color); 
                break;
            case 'updateDossierData':
                if (data.dossier) {
                    updateDossier(data.dossier);
                }
                break;
            case 'setupLocations':
                resetUI();
                const isNewChar = data.isNew === true;
                if (!isNewChar) {
                    createLocationItem('Last Location', 'current', 'current', 'fa-location-arrow');
                }
                if (data.locations) {
                    for (const key in data.locations) {
                        if (Object.hasOwnProperty.call(data.locations, key)) {
                            const loc = data.locations[key];
                            createLocationItem(loc.label, 'normal', key, 'fa-map-marker-alt');
                        }
                    }
                }
                if (data.houses && data.houses.length > 0) {
                    data.houses.forEach(house => {
                        createLocationItem(house.label, 'house', house.house, 'fa-home');
                    });
                }
                break;
            case 'setupAppartements':
                resetUI();
                if (data.locations) {
                    for (const key in data.locations) {
                        if (Object.hasOwnProperty.call(data.locations, key)) {
                            const loc = data.locations[key];
                            createLocationItem(loc.label, 'appartment', key, 'fa-building');
                        }
                    }
                }
                break;
        }
    });
});