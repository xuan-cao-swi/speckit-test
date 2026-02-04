// Shared utilities for Photo Album Organizer

/**
 * API helper to make fetch requests with error handling
 * @param {string} url - API endpoint
 * @param {object} options - Fetch options
 * @returns {Promise<any>} - Response data
 */
async function apiFetch(url, options = {}) {
    try {
        showLoading();
        
        const response = await fetch(url, {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        });
        
        hideLoading();
        
        if (!response.ok) {
            const error = await response.json().catch(() => ({ error: response.statusText }));
            throw new Error(error.reason || error.error || 'Request failed');
        }
        
        // Handle 204 No Content
        if (response.status === 204) {
            return null;
        }
        
        return await response.json();
    } catch (error) {
        hideLoading();
        showError(error.message);
        throw error;
    }
}

/**
 * Show loading indicator
 */
function showLoading() {
    const loader = document.getElementById('loadingIndicator');
    if (loader) {
        loader.style.display = 'block';
    }
}

/**
 * Hide loading indicator
 */
function hideLoading() {
    const loader = document.getElementById('loadingIndicator');
    if (loader) {
        loader.style.display = 'none';
    }
}

/**
 * Show error message
 * @param {string} message - Error message to display
 */
function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    const errorText = document.getElementById('errorText');
    
    if (errorDiv && errorText) {
        errorText.textContent = message;
        errorDiv.style.display = 'flex';
        
        // Auto-hide after 5 seconds
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 5000);
    }
}

/**
 * Hide error message
 */
function hideError() {
    const errorDiv = document.getElementById('errorMessage');
    if (errorDiv) {
        errorDiv.style.display = 'none';
    }
}

/**
 * Format date to readable string
 * @param {string|Date} date - Date to format
 * @returns {string} - Formatted date
 */
function formatDate(date) {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
    });
}

/**
 * Debounce function to limit rate of function calls
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @returns {Function} - Debounced function
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

/**
 * Escape HTML to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} - Escaped text
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Event listeners for error close button
document.addEventListener('DOMContentLoaded', () => {
    const closeErrorBtn = document.getElementById('closeError');
    if (closeErrorBtn) {
        closeErrorBtn.addEventListener('click', hideError);
    }
    
    // T174: Apply preferences on app load
    loadAndApplyPreferences();
    
    // T168: Settings button handler
    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn) {
        settingsBtn.addEventListener('click', showSettingsModal);
    }
    
    // Settings form submit
    const settingsForm = document.getElementById('settingsForm');
    if (settingsForm) {
        settingsForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await saveSettings();
        });
    }
    
    // T173: Thumbnail size slider live preview
    const thumbnailSlider = document.getElementById('thumbnailSizeSlider');
    const thumbnailValue = document.getElementById('thumbnailSizeValue');
    if (thumbnailSlider && thumbnailValue) {
        thumbnailSlider.addEventListener('input', (e) => {
            thumbnailValue.textContent = e.target.value;
        });
    }
});

// T169: Load user preferences from API
async function loadAndApplyPreferences() {
    try {
        const prefs = await fetch('/api/preferences').then(r => r.json());
        
        // T171: Apply theme
        applyTheme(prefs.theme);
        
        // Store preferences globally
        window.userPreferences = prefs;
        
        return prefs;
    } catch (error) {
        console.error('Failed to load preferences:', error);
        // Use defaults
        window.userPreferences = {
            theme: 'light',
            sortDirection: 'ASC',
            thumbnailSize: 200
        };
    }
}

// T171: Apply theme by updating CSS variables
function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    
    if (theme === 'dark') {
        document.documentElement.style.setProperty('--bg-primary', '#1a1a1a');
        document.documentElement.style.setProperty('--bg-secondary', '#2d2d2d');
        document.documentElement.style.setProperty('--text-primary', '#ffffff');
        document.documentElement.style.setProperty('--text-secondary', '#b0b0b0');
        document.documentElement.style.setProperty('--border-color', '#404040');
    } else {
        document.documentElement.style.setProperty('--bg-primary', '#ffffff');
        document.documentElement.style.setProperty('--bg-secondary', '#f5f5f5');
        document.documentElement.style.setProperty('--text-primary', '#1a1a1a');
        document.documentElement.style.setProperty('--text-secondary', '#666666');
        document.documentElement.style.setProperty('--border-color', '#e0e0e0');
    }
}

// Show settings modal
function showSettingsModal() {
    const modal = document.getElementById('settingsModal');
    const prefs = window.userPreferences || {};
    
    // Populate current values
    document.getElementById('themeSelect').value = prefs.theme || 'light';
    document.getElementById('sortDirectionSelect').value = prefs.sortDirection || 'ASC';
    document.getElementById('thumbnailSizeSlider').value = prefs.thumbnailSize || 200;
    document.getElementById('thumbnailSizeValue').textContent = prefs.thumbnailSize || 200;
    
    modal.style.display = 'flex';
}

// Hide settings modal
function hideSettingsModal() {
    document.getElementById('settingsModal').style.display = 'none';
}

// T170: Save settings via API
async function saveSettings() {
    const theme = document.getElementById('themeSelect').value;
    const sortDirection = document.getElementById('sortDirectionSelect').value;
    const thumbnailSize = parseInt(document.getElementById('thumbnailSizeSlider').value);
    
    try {
        const prefs = await apiFetch('/api/preferences', {
            method: 'PATCH',
            body: JSON.stringify({
                theme,
                sortDirection,
                thumbnailSize
            })
        });
        
        // Update global preferences
        window.userPreferences = prefs;
        
        // T171: Apply theme immediately
        applyTheme(theme);
        
        // T172: Reload albums if sort direction changed
        if (typeof loadAlbums === 'function') {
            await loadAlbums();
        }
        
        hideSettingsModal();
        showError('Settings saved successfully!', 'success');
    } catch (error) {
        console.error('Failed to save settings:', error);
    }
}
