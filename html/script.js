let markers = [];
let markersVisible = true;
let markerToDelete = null;
let markerToShare = null;
const gpsContainer = document.getElementById('gpsContainer');
const closeBtn = document.getElementById('closeBtn');
const markBtn = document.getElementById('markBtn');
const locationLabel = document.getElementById('locationLabel');
const toggleMarkers = document.getElementById('toggleMarkers');
const markersList = document.getElementById('markersList');
const markerCount = document.getElementById('markerCount');
const confirmModal = document.getElementById('confirmModal');
const shareModal = document.getElementById('shareModal');
const confirmDelete = document.getElementById('confirmDelete');
const cancelDelete = document.getElementById('cancelDelete');
const confirmShare = document.getElementById('confirmShare');
const cancelShare = document.getElementById('cancelShare');
const sharePlayerId = document.getElementById('sharePlayerId');
closeBtn.addEventListener('click', closeUI);
markBtn.addEventListener('click', markLocation);
toggleMarkers.addEventListener('change', toggleMarkersVisibility);
confirmDelete.addEventListener('click', handleConfirmDelete);
cancelDelete.addEventListener('click', closeConfirmModal);
confirmShare.addEventListener('click', handleConfirmShare);
cancelShare.addEventListener('click', closeShareModal);

locationLabel.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        markLocation();
    }
});
sharePlayerId.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleConfirmShare();
    }
});
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (confirmModal.classList.contains('active')) {
            closeConfirmModal();
        } else if (shareModal.classList.contains('active')) {
            closeShareModal();
        } else if (gpsContainer.classList.contains('active')) {
            closeUI();
        }
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'openUI':
            openUI(data.markers, data.markersVisible);
            break;
        case 'updateMarkers':
            updateMarkers(data.markers);
            break;
    }
});

function openUI(markersData, visible) {
    markers = markersData || [];
    markersVisible = visible !== undefined ? visible : true;
    
    gpsContainer.classList.add('active');
    toggleMarkers.checked = markersVisible;
    
    renderMarkers();
    locationLabel.value = '';
    locationLabel.focus();
}

function closeUI() {
    gpsContainer.classList.remove('active');
    fetch(`https://${resourceName}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function markLocation() {
    const label = locationLabel.value.trim();
    
    if (!label) {
        return;
    }
    
    fetch(`https://${resourceName}/markLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ label: label })
    });
    
    locationLabel.value = '';
}

function toggleMarkersVisibility() {
    markersVisible = toggleMarkers.checked;
    
    fetch(`https://${resourceName}/toggleMarkers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ visible: markersVisible })
    });
}

function updateMarkers(markersData) {
    markers = markersData || [];
    renderMarkers();
}

function renderMarkers() {
    markerCount.textContent = markers.length;
    markersList.innerHTML = '';
    
    if (markers.length === 0) {
        markersList.innerHTML = `
            <div class="empty-state">
                <p>No saved locations yet.<br>Mark your current location to get started!</p>
            </div>
        `;
        return;
    }
    
    markers.forEach((marker, index) => {
        const markerItem = createMarkerElement(marker, index);
        markersList.appendChild(markerItem);
    });
}

function createMarkerElement(marker, index) {
    const div = document.createElement('div');
    div.className = 'marker-item';
    
    const coords = `X: ${marker.coords.x.toFixed(1)}, Y: ${marker.coords.y.toFixed(1)}`;
    const date = marker.timestamp ? new Date(marker.timestamp * 1000).toLocaleString() : 'Unknown';
    
    div.innerHTML = `
        <div class="marker-header">
            <div class="marker-label">${escapeHtml(marker.label)}</div>
        </div>
        <div class="marker-info">
            ${marker.street ? `📍 ${escapeHtml(marker.street)}` : ''}<br>
            📌 ${coords}<br>
            🕐 ${date}
        </div>
        <div class="marker-actions">
            <button class="marker-btn waypoint" data-index="${index}">Waypoint</button>
            <button class="marker-btn share" data-index="${index}">Share</button>
            <button class="marker-btn delete" data-index="${index}">Remove</button>
        </div>
    `;
    const waypointBtn = div.querySelector('.waypoint');
    const shareBtn = div.querySelector('.share');
    const deleteBtn = div.querySelector('.delete');
    
    waypointBtn.addEventListener('click', () => setWaypoint(index));
    shareBtn.addEventListener('click', () => openShareModal(index));
    deleteBtn.addEventListener('click', () => openConfirmModal(index));
    
    return div;
}

function setWaypoint(index) {
    fetch(`https://${resourceName}/setWaypoint`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ index: index + 1 })
    });
}

function openConfirmModal(index) {
    markerToDelete = index;
    confirmModal.classList.add('active');
}

function closeConfirmModal() {
    markerToDelete = null;
    confirmModal.classList.remove('active');
}

function handleConfirmDelete() {
    if (markerToDelete !== null) {
        fetch(`https://${resourceName}/removeMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ index: markerToDelete + 1 })
        });
    }
    
    closeConfirmModal();
}

function openShareModal(index) {
    markerToShare = index;
    shareModal.classList.add('active');
    sharePlayerId.value = '';
    sharePlayerId.focus();
}

function closeShareModal() {
    markerToShare = null;
    shareModal.classList.remove('active');
    sharePlayerId.value = '';
}

function handleConfirmShare() {
    const playerId = parseInt(sharePlayerId.value);
    
    if (!playerId || playerId < 1) {
        return;
    }
    
    if (markerToShare !== null) {
        fetch(`https://${resourceName}/shareMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                playerId: playerId,
                index: markerToShare + 1
            })
        });
    }
    
    closeShareModal();
}

const resourceName = (typeof GetParentResourceName === 'function' && GetParentResourceName()) || 'Core_Gps';

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
