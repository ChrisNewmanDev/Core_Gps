let markers = [];
let markersVisible = true;
let markerToDelete = null;
let markerToShare = null;

// DOM Elements
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

// Event Listeners
closeBtn.addEventListener('click', closeUI);
markBtn.addEventListener('click', markLocation);
toggleMarkers.addEventListener('change', toggleMarkersVisibility);
confirmDelete.addEventListener('click', handleConfirmDelete);
cancelDelete.addEventListener('click', closeConfirmModal);
confirmShare.addEventListener('click', handleConfirmShare);
cancelShare.addEventListener('click', closeShareModal);

// Listen for Enter key on location input
locationLabel.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        markLocation();
    }
});

// Listen for Enter key on share input
sharePlayerId.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleConfirmShare();
    }
});

// Close UI on ESC key
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

// NUI Message Handler
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

// Open UI
function openUI(markersData, visible) {
    markers = markersData || [];
    markersVisible = visible !== undefined ? visible : true;
    
    gpsContainer.classList.add('active');
    toggleMarkers.checked = markersVisible;
    
    renderMarkers();
    locationLabel.value = '';
    locationLabel.focus();
}

// Close UI
function closeUI() {
    gpsContainer.classList.remove('active');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Mark Location
function markLocation() {
    const label = locationLabel.value.trim();
    
    if (!label) {
        // You could show an error message here
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/markLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ label: label })
    });
    
    locationLabel.value = '';
}

// Toggle Markers Visibility
function toggleMarkersVisibility() {
    markersVisible = toggleMarkers.checked;
    
    fetch(`https://${GetParentResourceName()}/toggleMarkers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ visible: markersVisible })
    });
}

// Update Markers
function updateMarkers(markersData) {
    markers = markersData || [];
    renderMarkers();
}

// Render Markers
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

// Create Marker Element
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
    
    // Add event listeners to buttons
    const waypointBtn = div.querySelector('.waypoint');
    const shareBtn = div.querySelector('.share');
    const deleteBtn = div.querySelector('.delete');
    
    waypointBtn.addEventListener('click', () => setWaypoint(index));
    shareBtn.addEventListener('click', () => openShareModal(index));
    deleteBtn.addEventListener('click', () => openConfirmModal(index));
    
    return div;
}

// Set Waypoint
function setWaypoint(index) {
    fetch(`https://${GetParentResourceName()}/setWaypoint`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ index: index + 1 })
    });
}

// Open Confirm Modal
function openConfirmModal(index) {
    markerToDelete = index;
    confirmModal.classList.add('active');
}

// Close Confirm Modal
function closeConfirmModal() {
    markerToDelete = null;
    confirmModal.classList.remove('active');
}

// Handle Confirm Delete
function handleConfirmDelete() {
    if (markerToDelete !== null) {
        fetch(`https://${GetParentResourceName()}/removeMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ index: markerToDelete + 1 })
        });
    }
    
    closeConfirmModal();
}

// Open Share Modal
function openShareModal(index) {
    markerToShare = index;
    shareModal.classList.add('active');
    sharePlayerId.value = '';
    sharePlayerId.focus();
}

// Close Share Modal
function closeShareModal() {
    markerToShare = null;
    shareModal.classList.remove('active');
    sharePlayerId.value = '';
}

// Handle Confirm Share
function handleConfirmShare() {
    const playerId = parseInt(sharePlayerId.value);
    
    if (!playerId || playerId < 1) {
        // Invalid player ID
        return;
    }
    
    if (markerToShare !== null) {
        fetch(`https://${GetParentResourceName()}/shareMarker`, {
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

// Helper function to get resource name
function GetParentResourceName() {
    return window.location.hostname === '' ? 'core_gps' : window.location.hostname;
}

// Helper function to escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
