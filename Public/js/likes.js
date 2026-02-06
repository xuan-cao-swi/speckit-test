// Public/js/likes.js
// T028: Like button component with polling and optimistic updates

/**
 * LikeButton - Component for like/unlike functionality with real-time updates
 * 
 * Features:
 * - Optimistic UI updates for immediate feedback
 * - HTTP polling (2-second interval) for like count updates
 * - Self-like prevention (disabled state for owned content)
 * - Error handling with user feedback
 * - ARIA accessibility support
 */
class LikeButton {
    /**
     * @param {Object} options
     * @param {string} options.targetType - 'photo' or 'album'
     * @param {string} options.targetId - UUID of the photo or album
     * @param {HTMLElement} options.container - Container element to render the button
     * @param {boolean} [options.enablePolling=true] - Whether to enable polling for updates
     */
    constructor(options) {
        this.targetType = options.targetType;
        this.targetId = options.targetId;
        this.container = options.container;
        this.enablePolling = options.enablePolling !== false;
        
        this.likeCount = 0;
        this.isLiked = false;
        this.isOwnedByCurrentUser = false;
        this.isLoading = false;
        this.pollingInterval = null;
        
        this.init();
    }
    
    async init() {
        await this.fetchLikeInfo();
        this.render();
        
        if (this.enablePolling) {
            this.startPolling();
        }
    }
    
    /**
     * Fetch current like information from the API
     */
    async fetchLikeInfo() {
        try {
            const endpoint = `/api/${this.targetType}s/${this.targetId}/likes`;
            const response = await fetch(endpoint, {
                credentials: 'include'
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const data = await response.json();
            this.likeCount = data.likeCount;
            this.isLiked = data.isLikedByCurrentUser;
            this.isOwnedByCurrentUser = data.isOwnedByCurrentUser || false;
            
        } catch (error) {
            console.error('Failed to fetch like info:', error);
        }
    }
    
    /**
     * Render the like button UI
     */
    render() {
        const isDisabled = this.isOwnedByCurrentUser || this.isLoading;
        const buttonClass = `like-button ${this.isLiked ? 'liked' : ''} ${isDisabled ? 'disabled' : ''}`;
        const heartIcon = this.isLiked ? '❤️' : '🤍';
        const ariaLabel = this.isOwnedByCurrentUser 
            ? 'You cannot like your own content'
            : this.isLiked 
                ? `Unlike this ${this.targetType}. Currently ${this.likeCount} likes.`
                : `Like this ${this.targetType}. Currently ${this.likeCount} likes.`;
        
        this.container.innerHTML = `
            <button 
                class="${buttonClass}"
                onclick="window.likeButtons['${this.targetType}-${this.targetId}'].toggle()"
                ${isDisabled ? 'disabled' : ''}
                aria-label="${ariaLabel}"
                aria-pressed="${this.isLiked}"
                title="${this.isOwnedByCurrentUser ? 'You cannot like your own content' : ''}"
            >
                <span class="like-icon" aria-hidden="true">${heartIcon}</span>
                <span class="like-count" aria-live="polite">${this.likeCount}</span>
            </button>
            ${this.likeCount > 0 ? `
                <button 
                    class="likers-link"
                    onclick="window.likeButtons['${this.targetType}-${this.targetId}'].showLikers()"
                    aria-label="See who liked this ${this.targetType}"
                >
                    ${this.likeCount === 1 ? '1 person' : `${this.likeCount} people`} liked this
                </button>
            ` : ''}
        `;
    }
    
    /**
     * Toggle like state (optimistic update)
     */
    async toggle() {
        if (this.isOwnedByCurrentUser || this.isLoading) {
            return;
        }
        
        // Optimistic update
        const previousState = { isLiked: this.isLiked, likeCount: this.likeCount };
        this.isLiked = !this.isLiked;
        this.likeCount += this.isLiked ? 1 : -1;
        this.likeCount = Math.max(0, this.likeCount);
        this.isLoading = true;
        this.render();
        
        try {
            const endpoint = `/api/${this.targetType}s/${this.targetId}/like`;
            const method = this.isLiked ? 'POST' : 'DELETE';
            
            const response = await fetch(endpoint, {
                method,
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            if (!response.ok) {
                // Rollback optimistic update
                this.isLiked = previousState.isLiked;
                this.likeCount = previousState.likeCount;
                
                if (response.status === 401) {
                    showLikeError('Please log in to like content');
                } else if (response.status === 400) {
                    showLikeError('Cannot like your own content');
                } else {
                    showLikeError('Failed to update like');
                }
            } else if (this.isLiked) {
                // Update with server response
                const data = await response.json();
                this.likeCount = data.likeCount;
            }
            
        } catch (error) {
            // Rollback optimistic update
            this.isLiked = previousState.isLiked;
            this.likeCount = previousState.likeCount;
            console.error('Like toggle failed:', error);
            showLikeError('Network error. Please try again.');
        } finally {
            this.isLoading = false;
            this.render();
        }
    }
    
    /**
     * Start polling for like count updates (2-second interval)
     */
    startPolling() {
        this.stopPolling(); // Clear any existing interval
        
        this.pollingInterval = setInterval(async () => {
            if (!document.hidden && !this.isLoading) {
                await this.fetchLikeInfo();
                this.render();
            }
        }, 2000);
    }
    
    /**
     * Stop polling
     */
    stopPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }
    
    /**
     * Show modal with list of users who liked this content (User Story 4)
     */
    async showLikers() {
        try {
            const endpoint = `/api/${this.targetType}s/${this.targetId}/likers?limit=50`;
            const response = await fetch(endpoint, {
                credentials: 'include'
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const data = await response.json();
            showLikersModal(this.targetType, this.targetId, data);
            
        } catch (error) {
            console.error('Failed to fetch likers:', error);
            showLikeError('Failed to load likers list');
        }
    }
    
    /**
     * Cleanup when component is destroyed
     */
    destroy() {
        this.stopPolling();
    }
}

// Global storage for like button instances
window.likeButtons = window.likeButtons || {};

/**
 * Create or update a like button for a photo
 * @param {string} photoId - UUID of the photo
 * @param {HTMLElement} container - Container element
 * @returns {LikeButton}
 */
function createPhotoLikeButton(photoId, container) {
    const key = `photo-${photoId}`;
    
    // Cleanup existing instance
    if (window.likeButtons[key]) {
        window.likeButtons[key].destroy();
    }
    
    // Create new instance
    window.likeButtons[key] = new LikeButton({
        targetType: 'photo',
        targetId: photoId,
        container
    });
    
    return window.likeButtons[key];
}

/**
 * Create or update a like button for an album
 * @param {string} albumId - UUID of the album
 * @param {HTMLElement} container - Container element
 * @returns {LikeButton}
 */
function createAlbumLikeButton(albumId, container) {
    const key = `album-${albumId}`;
    
    // Cleanup existing instance
    if (window.likeButtons[key]) {
        window.likeButtons[key].destroy();
    }
    
    // Create new instance
    window.likeButtons[key] = new LikeButton({
        targetType: 'album',
        targetId: albumId,
        container
    });
    
    return window.likeButtons[key];
}

/**
 * Show error message to user
 * @param {string} message
 */
function showLikeError(message) {
    // Try to use existing error display function
    if (typeof showError === 'function') {
        showError(message);
    } else {
        // Fallback: create toast notification
        const toast = document.createElement('div');
        toast.className = 'like-toast error';
        toast.textContent = message;
        toast.setAttribute('role', 'alert');
        document.body.appendChild(toast);
        
        setTimeout(() => toast.remove(), 3000);
    }
}

/**
 * Show modal with list of users who liked content (User Story 4)
 * @param {string} targetType - 'photo' or 'album'
 * @param {string} targetId - UUID of the content
 * @param {Object} data - Likers response data
 */
function showLikersModal(targetType, targetId, data) {
    // Remove any existing modal
    const existingModal = document.querySelector('.likers-modal');
    if (existingModal) {
        existingModal.remove();
    }
    
    const likersList = data.likers.map(liker => {
        const likedAt = new Date(liker.likedAt).toLocaleDateString();
        return `<li class="liker-item">
            <span class="liker-username">${escapeHtml(liker.username)}</span>
            <span class="liker-date">${likedAt}</span>
        </li>`;
    }).join('');
    
    const modal = document.createElement('div');
    modal.className = 'likers-modal';
    modal.setAttribute('role', 'dialog');
    modal.setAttribute('aria-labelledby', 'likers-modal-title');
    modal.innerHTML = `
        <div class="likers-modal-backdrop" onclick="closeLikersModal()"></div>
        <div class="likers-modal-content">
            <header class="likers-modal-header">
                <h2 id="likers-modal-title">Likes</h2>
                <button class="likers-modal-close" onclick="closeLikersModal()" aria-label="Close">×</button>
            </header>
            <div class="likers-modal-body">
                ${data.totalCount === 0 
                    ? '<p class="likers-empty">No likes yet</p>'
                    : `<ul class="likers-list">${likersList}</ul>`
                }
                ${data.hasMore 
                    ? `<button class="likers-load-more" onclick="loadMoreLikers('${targetType}', '${targetId}')">
                        Load more...
                       </button>`
                    : ''
                }
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Focus trap for accessibility
    modal.querySelector('.likers-modal-close').focus();
    
    // Close on escape key
    modal.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeLikersModal();
        }
    });
}

/**
 * Close the likers modal
 */
function closeLikersModal() {
    const modal = document.querySelector('.likers-modal');
    if (modal) {
        modal.remove();
    }
}

/**
 * Load more likers (pagination)
 */
async function loadMoreLikers(targetType, targetId) {
    // Get current count to use as offset
    const list = document.querySelector('.likers-list');
    const currentCount = list ? list.children.length : 0;
    
    try {
        const endpoint = `/api/${targetType}s/${targetId}/likers?limit=50&offset=${currentCount}`;
        const response = await fetch(endpoint, {
            credentials: 'include'
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        
        // Append new likers
        data.likers.forEach(liker => {
            const li = document.createElement('li');
            li.className = 'liker-item';
            const likedAt = new Date(liker.likedAt).toLocaleDateString();
            li.innerHTML = `
                <span class="liker-username">${escapeHtml(liker.username)}</span>
                <span class="liker-date">${likedAt}</span>
            `;
            list.appendChild(li);
        });
        
        // Hide load more button if no more results
        if (!data.hasMore) {
            const loadMoreBtn = document.querySelector('.likers-load-more');
            if (loadMoreBtn) {
                loadMoreBtn.remove();
            }
        }
        
    } catch (error) {
        console.error('Failed to load more likers:', error);
        showLikeError('Failed to load more');
    }
}

/**
 * Utility function to escape HTML
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Cleanup all like buttons (call when navigating away)
 */
function destroyAllLikeButtons() {
    Object.values(window.likeButtons).forEach(button => {
        if (button && typeof button.destroy === 'function') {
            button.destroy();
        }
    });
    window.likeButtons = {};
}

// Pause polling when page is hidden, resume when visible
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        // Pause all polling
        Object.values(window.likeButtons).forEach(button => {
            if (button) button.stopPolling();
        });
    } else {
        // Resume all polling
        Object.values(window.likeButtons).forEach(button => {
            if (button && button.enablePolling) button.startPolling();
        });
    }
});
