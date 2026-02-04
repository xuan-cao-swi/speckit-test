// Photo management JavaScript

// T046: Photo grid state
const PhotoState = {
    photos: [],
    currentAlbumId: null
};

// T047: Load photos for an album
async function loadPhotos(albumId) {
    try {
        PhotoState.currentAlbumId = albumId;
        const photos = await apiFetch(`/api/albums/${albumId}/photos`);
        PhotoState.photos = photos;
        renderPhotoGrid();
    } catch (error) {
        console.error('Failed to load photos:', error);
        showError('Failed to load photos');
    }
}

// T048: Render photo grid
function renderPhotoGrid() {
    const photoGrid = document.getElementById('photoGrid');
    const emptyState = document.getElementById('photoEmptyState');
    
    if (!PhotoState.photos || PhotoState.photos.length === 0) {
        photoGrid.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    photoGrid.innerHTML = PhotoState.photos.map(photo => `
        <div class="photo-tile" role="listitem" data-photo-id="${photo.id}" aria-label="Photo ${photo.displayOrder + 1}">
            <img 
                src="/api/photos/${photo.id}/thumbnail" 
                alt="Photo ${photo.displayOrder + 1}" 
                loading="lazy"
                onerror="this.src='/images/placeholder.jpg'"
            >
        </div>
    `).join('');
}

// Initialize photo-related event listeners
document.addEventListener('DOMContentLoaded', () => {
    // Photo add button will be implemented in User Story 4
    const addPhotosBtn = document.getElementById('addPhotosBtn');
    if (addPhotosBtn) {
        addPhotosBtn.addEventListener('click', () => {
            // TODO: Implement in US4
            showError('Photo upload will be implemented in User Story 4');
        });
    }
});
