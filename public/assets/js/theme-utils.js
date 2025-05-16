/**
 * Theme utilities for LifeQuestRPG
 */

/**
 * Update user theme preference via AJAX
 * @param {string} theme - The selected theme ('light' or 'dark')
 */
function updateUserThemePreference(theme) {
    // Only proceed if user is logged in
    if (!document.body.classList.contains('logged-in')) {
        return;
    }

    // Get the current color scheme from localStorage or default
    const colorScheme = localStorage.getItem('colorScheme') || 'default';

    // Create form data
    const formData = new FormData();
    formData.append('update_type', 'theme');
    formData.append('theme', theme);
    formData.append('color_scheme', colorScheme);

    // Send AJAX request to update theme
    fetch('/settings/update', {
        method: 'POST',
        body: formData,
        headers: {
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
    .then(response => response.json())
    
    .catch(error => {
        console.error('Error updating theme:', error);
    });
}

/**
 * Simple toast notification system
 * @param {string} message - Message to display
 * @param {string} type - Type of toast (success, error, info)
 */
function showToast(message, type = 'info') {
    // Create toast container if it doesn't exist
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }

    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');

    // Create toast content
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">
                ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    `;

    // Add toast to container
    toastContainer.appendChild(toast);

    // Initialize and show using Bootstrap's API
    const bsToast = new bootstrap.Toast(toast, { autohide: true, delay: 3000 });
    bsToast.show();

    // Remove from DOM after hidden
    toast.addEventListener('hidden.bs.toast', function() {
        toast.remove();
    });
}
