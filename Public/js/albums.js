// Album management JavaScript

// T042: Application state
const AppState = {
    albums: [],
    currentView: 'list', // 'list' or 'detail'
    currentAlbumId: null
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
    
    if (!AppState.albums || AppState.albums.length === 0) {
        albumGrid.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    albumGrid.innerHTML = AppState.albums.map(album => `
        <article class="album-card" role="listitem" data-album-id="${album.id}" aria-label="Album: ${escapeHtml(album.name)}">
            <div class="album-cover" style="background-color: #ddd;">
                ${album.coverPhotoId ? `<img src="/api/photos/${album.coverPhotoId}/thumbnail" alt="${escapeHtml(album.name)} cover">` : ''}
            </div>
            <div class="album-info">
                <h3 class="album-name">${escapeHtml(album.name)}</h3>
                <p class="album-date">${formatDate(album.date)}</p>
                <p class="album-count">${album.photos?.length || 0} photos</p>
            </div>
        </article>
    `).join('');
    
    // T045: Add click handlers to navigate to album detail
    document.querySelectorAll('.album-card').forEach(card => {
        card.addEventListener('click', () => {
            const albumId = card.dataset.albumId;
            showAlbumDetail(albumId);
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

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    // T045: Back button handler
    document.getElementById('backBtn').addEventListener('click', showAlbumList);
    
    // Load albums on startup
    loadAlbums();
});
