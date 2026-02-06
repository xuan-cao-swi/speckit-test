// Album management JavaScript

// T042: Application state
const AppState = {
    albums: [],
    currentView: 'list', // 'list' or 'detail'
    currentAlbumId: null,
    albumLikeButtons: {} // T031: Track like button instances for albums
};

// T043: Load albums from API
async function loadAlbums() {
    try {
        const albums = await apiFetch('/api/albums');
        AppState.albums = albums;
        renderAlbums();
    } catch (error) {
        console.error('Failed to load albums:', error);
    }
}

// T044: Render album grid
function renderAlbums() {
    const albumGrid = document.getElementById('albumGrid');
    const emptyState = document.getElementById('emptyState');
    
    // T031: Clean up existing like buttons
    Object.values(AppState.albumLikeButtons).forEach(btn => btn.destroy());
    AppState.albumLikeButtons = {};
    
    if (!AppState.albums || AppState.albums.length === 0) {
        albumGrid.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    // T123: Add draggable attribute to album cards
    albumGrid.innerHTML = AppState.albums.map(album => `
        <article class="album-card" 
                 draggable="true" 
                 role="listitem" 
                 data-album-id="${album.id}" 
                 aria-label="Album: ${escapeHtml(album.name)}">
            <div class="album-cover" style="background-color: #ddd;">
                ${album.coverPhotoId ? `<img src="/api/photos/${album.coverPhotoId}/thumbnail" alt="${escapeHtml(album.name)} cover">` : ''}
            </div>
            <div class="album-info">
                <h3 class="album-name">${escapeHtml(album.name)}</h3>
                <p class="album-date">${formatDate(album.date)}</p>
                <p class="album-count">${album.photos?.length || 0} photos</p>
            </div>
            <div class="album-actions">
                <div id="album-like-${album.id}" class="album-like-container"></div>
                <button class="btn-icon edit-album" data-album-id="${album.id}" aria-label="Edit ${escapeHtml(album.name)}">✏️</button>
                <button class="btn-icon delete-album" data-album-id="${album.id}" aria-label="Delete ${escapeHtml(album.name)}">🗑️</button>
            </div>
        </article>
    `).join('');
    
    // T031: Initialize like buttons for each album
    AppState.albums.forEach(album => {
        initAlbumLikeButton(album.id);
    });
    
    // T123: Setup drag-and-drop handlers
    setupDragAndDrop();
    
    // T045: Add click handlers to navigate to album detail
    document.querySelectorAll('.album-card .album-cover, .album-card .album-info').forEach(element => {
        element.addEventListener('click', (e) => {
            const card = e.target.closest('.album-card');
            const albumId = card.dataset.albumId;
            showAlbumDetail(albumId);
        });
    });
    
    // T071: Edit album handlers
    document.querySelectorAll('.edit-album').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const albumId = btn.dataset.albumId;
            showAlbumModal(albumId);
        });
    });
    
    // T073: Delete album handlers
    document.querySelectorAll('.delete-album').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const albumId = btn.dataset.albumId;
            const album = AppState.albums.find(a => a.id === albumId);
            if (album) {
                deleteAlbum(albumId, album.name);
            }
        });
    });
}

// Show album detail view
function showAlbumDetail(albumId) {
    AppState.currentView = 'detail';
    AppState.currentAlbumId = albumId;
    
    // Hide album list, show album detail
    document.getElementById('albumListView').style.display = 'none';
    document.getElementById('albumDetailView').style.display = 'block';
    document.getElementById('backBtn').style.display = 'inline-block';
    document.getElementById('createAlbumBtn').style.display = 'none';
    
    // Load photos for this album
    loadPhotos(albumId);
    
    // Update album header
    const album = AppState.albums.find(a => a.id === albumId);
    if (album) {
        document.getElementById('albumTitle').textContent = album.name;
        document.getElementById('albumDate').textContent = formatDate(album.date);
    }
}

// T049: Back to album list
function showAlbumList() {
    AppState.currentView = 'list';
    AppState.currentAlbumId = null;
    
    document.getElementById('albumListView').style.display = 'block';
    document.getElementById('albumDetailView').style.display = 'none';
    document.getElementById('backBtn').style.display = 'none';
    document.getElementById('createAlbumBtn').style.display = 'inline-block';
}

// T031: Initialize a like button for an album
function initAlbumLikeButton(albumId) {
    const container = document.getElementById(`album-like-${albumId}`);
    if (container && typeof LikeButton !== 'undefined') {
        AppState.albumLikeButtons[albumId] = new LikeButton({
            targetType: 'album',
            targetId: albumId,
            container: container
        });
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    // T045: Back button handler
    document.getElementById('backBtn').addEventListener('click', showAlbumList);
    
    // T069: Create album button handler
    document.getElementById('createAlbumBtn').addEventListener('click', () => {
        showAlbumModal();
    });
    
    // Modal close handlers
    document.querySelectorAll('.modal .close-btn, .modal .cancel-btn').forEach(btn => {
        btn.addEventListener('click', hideAlbumModal);
    });
    
    // T070: Album form submit handler
    document.getElementById('albumForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        await submitAlbumForm();
    });
    
    // Load albums on startup
    loadAlbums();
});

// T069: Show album creation/edit modal
let editingAlbumId = null;

function showAlbumModal(albumId = null) {
    const modal = document.getElementById('albumModal');
    const modalTitle = document.getElementById('modalTitle');
    const albumNameInput = document.getElementById('albumName');
    const albumDateInput = document.getElementById('albumDate');
    
    editingAlbumId = albumId;
    
    if (albumId) {
        // Edit mode
        modalTitle.textContent = 'Edit Album';
        const album = AppState.albums.find(a => a.id === albumId);
        if (album) {
            albumNameInput.value = album.name;
            albumDateInput.value = album.date.split('T')[0];
        }
    } else {
        // Create mode
        modalTitle.textContent = 'Create Album';
        albumNameInput.value = '';
        albumDateInput.value = new Date().toISOString().split('T')[0];
    }
    
    modal.style.display = 'flex';
    albumNameInput.focus(); // Focus on first input for keyboard accessibility
}

function hideAlbumModal() {
    document.getElementById('albumModal').style.display = 'none';
    editingAlbumId = null;
}

// T077: Keyboard shortcuts for modal
document.addEventListener('keydown', (e) => {
    const modal = document.getElementById('albumModal');
    if (modal && modal.style.display === 'flex') {
        if (e.key === 'Escape') {
            hideAlbumModal();
        } else if (e.key === 'Enter' && e.target.tagName !== 'TEXTAREA') {
            e.preventDefault();
            submitAlbumForm();
        }
    }
});

// T070/T072: Submit album form (create or update)
async function submitAlbumForm() {
    const name = document.getElementById('albumName').value.trim();
    const date = document.getElementById('albumDate').value;
    
    // Client-side validation
    if (!name || name.length > 255) {
        showError('Album name must be between 1 and 255 characters');
        return;
    }
    
    try {
        const data = { name, date };
        
        if (editingAlbumId) {
            // Update existing album
            await apiFetch(`/api/albums/${editingAlbumId}`, {
                method: 'PATCH',
                body: JSON.stringify(data)
            });
        } else {
            // Create new album
            await apiFetch('/api/albums', {
                method: 'POST',
                body: JSON.stringify(data)
            });
        }
        
        hideAlbumModal();
        await loadAlbums();
    } catch (error) {
        // Error already shown by apiFetch
    }
}

// T073: Delete album with confirmation
async function deleteAlbum(albumId, albumName) {
    if (!confirm(`Are you sure you want to delete "${albumName}"? This will also delete all photos in this album.`)) {
        return;
    }
    
    try {
        await apiFetch(`/api/albums/${albumId}`, {
            method: 'DELETE'
        });
        
        await loadAlbums();
    } catch (error) {
        // Error already shown by apiFetch
    }
}

// T123-T134: Drag and Drop Implementation
let draggedElement = null;
let draggedIndex = null;

function setupDragAndDrop() {
    const cards = document.querySelectorAll('.album-card');
    
    cards.forEach((card, index) => {
        // T123: Drag start
        card.addEventListener('dragstart', (e) => {
            draggedElement = card;
            draggedIndex = index;
            card.classList.add('dragging'); // T132: Drag state CSS
            e.dataTransfer.effectAllowed = 'move';
        });
        
        // T123: Drag end
        card.addEventListener('dragend', (e) => {
            card.classList.remove('dragging');
            document.querySelectorAll('.album-card').forEach(c => c.classList.remove('drag-over'));
        });
        
        // T123: Drag over
        card.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            
            if (card !== draggedElement) {
                card.classList.add('drag-over'); // T132: Drop zone indicator
            }
        });
        
        // Drag leave
        card.addEventListener('dragleave', (e) => {
            card.classList.remove('drag-over');
        });
        
        // T123: Drop event
        card.addEventListener('drop', async (e) => {
            e.preventDefault();
            card.classList.remove('drag-over');
            
            if (draggedElement && draggedElement !== card) {
                const dropIndex = Array.from(cards).indexOf(card);
                await handleDrop(draggedIndex, dropIndex);
            }
        });
    });
}

// T125-T126: Calculate new order and submit reorder
let reorderTimeout = null;
async function handleDrop(fromIndex, toIndex) {
    // T127: Optimistic UI update
    const movedAlbum = AppState.albums.splice(fromIndex, 1)[0];
    AppState.albums.splice(toIndex, 0, movedAlbum);
    renderAlbums();
    
    // T128: Debounce API call (500ms)
    clearTimeout(reorderTimeout);
    reorderTimeout = setTimeout(async () => {
        try {
            // T125: Calculate new custom order values
            const updates = AppState.albums.map((album, idx) => ({
                id: album.id,
                customOrder: idx
            }));
            
            // T126: Submit reorder to API
            await apiFetch('/api/albums/reorder', {
                method: 'PATCH',
                body: JSON.stringify({ updates })
            });
        } catch (error) {
            console.error('Reorder failed:', error);
            // T129: Rollback on error
            await loadAlbums(); // Reload from server to restore correct order
            showError('Failed to reorder albums. Restoring original order.');
        }
    }, 500);
}

// T130-T131: Reset to date order
async function resetToDateOrder() {
    try {
        // Set all customOrder to null
        const updates = AppState.albums.map(album => ({
            id: album.id,
            customOrder: null
        }));
        
        await apiFetch('/api/albums/reorder', {
            method: 'PATCH',
            body: JSON.stringify({ updates })
        });
        
        await loadAlbums(); // Reload with date sorting
    } catch (error) {
        showError('Failed to reset order');
    }
}
