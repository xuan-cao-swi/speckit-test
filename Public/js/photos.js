// Photo management JavaScript

// T046: Photo grid state
const PhotoState = {
    photos: [],
    currentAlbumId: null,
    likeButtons: {} // T030: Track like button instances
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
    
    // T030: Clean up existing like buttons
    Object.values(PhotoState.likeButtons).forEach(btn => btn.destroy());
    PhotoState.likeButtons = {};
    
    if (!PhotoState.photos || PhotoState.photos.length === 0) {
        photoGrid.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    // T103: Render photo tile with delete button and like button
    photoGrid.innerHTML = PhotoState.photos.map((photo, index) => `
        <div class="photo-tile" 
             role="listitem" 
             data-photo-id="${photo.id}" 
             data-photo-index="${index}"
             aria-label="Photo ${photo.displayOrder + 1}">
            <img 
                src="/api/photos/${photo.id}/thumbnail" 
                alt="Photo ${photo.displayOrder + 1}" 
                loading="lazy"
                onclick="openPhotoViewer(${index})"
                style="cursor: pointer;"
                onerror="this.src='/images/placeholder.jpg'"
            >
            <div class="photo-tile-actions">
                <div id="photo-like-${photo.id}" class="photo-tile-like"></div>
                <button 
                    class="photo-delete-btn btn-icon" 
                    onclick="deletePhoto('${photo.id}')"
                    aria-label="Delete photo"
                    title="Delete photo"
                >
                    <span aria-hidden="true">×</span>
                </button>
            </div>
        </div>
    `).join('');
    
    // T030: Initialize like buttons for each photo
    PhotoState.photos.forEach(photo => {
        initPhotoLikeButton(photo.id);
    });
}

// T030: Initialize a like button for a photo
function initPhotoLikeButton(photoId) {
    const container = document.getElementById(`photo-like-${photoId}`);
    if (container && typeof LikeButton !== 'undefined') {
        PhotoState.likeButtons[photoId] = new LikeButton({
            targetType: 'photo',
            targetId: photoId,
            container: container
        });
    }
}
}

// T101-T102: Handle photo file selection and upload
async function handlePhotoSelection() {
    const fileInput = document.getElementById('photoFileInput');
    const files = Array.from(fileInput.files);
    
    if (!files.length || !PhotoState.currentAlbumId) {
        return;
    }
    
    // Note: In a real browser environment, we can't access file paths directly for security reasons
    // This implementation would need to use FormData and multipart/form-data upload
    // For now, we'll implement a simplified version that would work with local file paths
    
    try {
        // Show loading state
        showError('Uploading photos...', 'info');
        
        // For demo purposes, we'll use the file names as paths
        // In production, this would upload files as multipart/form-data
        const filePaths = files.map(file => `/photos/${file.name}`);
        
        const newPhotos = await apiFetch(`/api/albums/${PhotoState.currentAlbumId}/photos`, {
            method: 'POST',
            body: JSON.stringify({ filePaths })
        });
        
        // Reload photos to show updated grid
        await loadPhotos(PhotoState.currentAlbumId);
        
        // Clear file input
        fileInput.value = '';
        
        showError(`Successfully added ${newPhotos.length} photo(s)`, 'success');
    } catch (error) {
        console.error('Failed to upload photos:', error);
        showError('Failed to upload photos. Please try again.');
    }
}

// T104-T105: Delete photo with confirmation
async function deletePhoto(photoId) {
    if (!confirm('Are you sure you want to delete this photo?')) {
        return;
    }
    
    try {
        await apiFetch(`/api/photos/${photoId}`, {
            method: 'DELETE'
        });
        
        // Reload photos to show updated grid
        await loadPhotos(PhotoState.currentAlbumId);
    } catch (error) {
        console.error('Failed to delete photo:', error);
        showError('Failed to delete photo. Please try again.');
    }
}

// Initialize photo-related event listeners
document.addEventListener('DOMContentLoaded', () => {
    // T101: Photo add button click handler
    const addPhotosBtn = document.getElementById('addPhotosBtn');
    const photoFileInput = document.getElementById('photoFileInput');
    
    if (addPhotosBtn && photoFileInput) {
        addPhotosBtn.addEventListener('click', () => {
            photoFileInput.click(); // Trigger file picker
        });
        
        photoFileInput.addEventListener('change', handlePhotoSelection);
    }
    
    // T147: Keyboard navigation for photo viewer
    document.addEventListener('keydown', (e) => {
        const modal = document.getElementById('photoViewerModal');
        if (modal && modal.style.display !== 'none') {
            if (e.key === 'ArrowLeft') {
                navigatePhoto(-1);
            } else if (e.key === 'ArrowRight') {
                navigatePhoto(1);
            } else if (e.key === 'Escape') {
                closePhotoViewer();
            }
        }
    });
});

// T144-T155: Full-screen photo viewer implementation
let currentPhotoIndex = 0;
let viewerLikeButton = null; // T030: Like button for viewer

function openPhotoViewer(photoIndex) {
    if (!PhotoState.photos || PhotoState.photos.length === 0) return;
    
    currentPhotoIndex = photoIndex;
    const modal = document.getElementById('photoViewerModal');
    modal.style.display = 'flex';
    
    renderFullscreenPhoto();
    
    // T155: Focus trap - focus on modal
    modal.focus();
}

function renderFullscreenPhoto() {
    const photo = PhotoState.photos[currentPhotoIndex];
    if (!photo) return;
    
    const viewerImage = document.getElementById('viewerImage');
    const viewerIndex = document.getElementById('viewerIndex');
    
    // T145: Display full-resolution image
    viewerImage.src = photo.filePath;
    viewerImage.alt = `Photo ${currentPhotoIndex + 1} of ${PhotoState.photos.length}`;
    
    // T150: Show photo index
    viewerIndex.textContent = `${currentPhotoIndex + 1} / ${PhotoState.photos.length}`;
    
    // T030: Update like button in viewer
    const viewerLikeContainer = document.getElementById('viewerLikeContainer');
    if (viewerLikeContainer && typeof LikeButton !== 'undefined') {
        // Destroy existing like button if any
        if (viewerLikeButton) {
            viewerLikeButton.destroy();
        }
        viewerLikeContainer.innerHTML = '';
        viewerLikeButton = new LikeButton({
            targetType: 'photo',
            targetId: photo.id,
            container: viewerLikeContainer,
            showCount: true
        });
    }
    
    // T154: Error handling for missing files
    viewerImage.onerror = () => {
        viewerImage.src = '/images/placeholder.jpg';
    };
    
    // T153: Preload next/prev images
    if (currentPhotoIndex > 0) {
        const prevImg = new Image();
        prevImg.src = PhotoState.photos[currentPhotoIndex - 1].filePath;
    }
    if (currentPhotoIndex < PhotoState.photos.length - 1) {
        const nextImg = new Image();
        nextImg.src = PhotoState.photos[currentPhotoIndex + 1].filePath;
    }
}

function navigatePhoto(direction) {
    const newIndex = currentPhotoIndex + direction;
    
    if (newIndex >= 0 && newIndex < PhotoState.photos.length) {
        currentPhotoIndex = newIndex;
        renderFullscreenPhoto();
    }
}

function closePhotoViewer() {
    const modal = document.getElementById('photoViewerModal');
    modal.style.display = 'none';
    
    // T030: Clean up viewer like button
    if (viewerLikeButton) {
        viewerLikeButton.destroy();
        viewerLikeButton = null;
    }
}
