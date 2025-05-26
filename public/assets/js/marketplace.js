/**
 * Market and Inventory Item Management
 * Handles item purchase, use, and UI interactions
 */

document.addEventListener('DOMContentLoaded', function() {
    // Item usage buttons
    const useItemButtons = document.querySelectorAll('.use-item-btn');
    
    if (useItemButtons.length > 0) {
        useItemButtons.forEach(button => {
            button.addEventListener('click', handleItemUse);
        });
    }
    
    // Category filter form submission
    const categoryFilter = document.getElementById('categoryFilter');
    if (categoryFilter) {
        categoryFilter.addEventListener('change', function() {
            this.closest('form').submit();
        });
    }
    
    // Check for success/error messages in session and show toast
    const successToast = document.getElementById('successToast');
    const errorToast = document.getElementById('errorToast');
    
    if (successToast && successToast.querySelector('.toast-body').textContent.trim()) {
        const toast = new bootstrap.Toast(successToast);
        toast.show();
    }
    
    if (errorToast && errorToast.querySelector('.toast-body').textContent.trim()) {
        const toast = new bootstrap.Toast(errorToast);
        toast.show();
    }
});

/**
 * Handle item use button click
 */
function handleItemUse(event) {
    const button = event.currentTarget;
    const inventoryId = button.dataset.inventoryId;
    const itemCard = button.closest('.item-card');
    const itemType = itemCard.dataset.itemType;
    
    // Show confirmation modal
    showItemUseConfirmation(
        inventoryId, 
        itemCard.querySelector('h3').textContent,
        itemType,
        function() {
            // On confirm callback
            useItem(inventoryId, button);
        }
    );
}

/**
 * Show confirmation modal for using an item
 */
function showItemUseConfirmation(inventoryId, itemName, itemType, onConfirm) {
    // Create modal if it doesn't exist
    let modal = document.getElementById('itemUseModal');
    if (!modal) {
        modal = createUseItemModal();
        document.body.appendChild(modal);
    }
    
    // Set modal content
    const modalTitle = modal.querySelector('.modal-title');
    const modalItemName = modal.querySelector('#modalItemName');
    const confirmButton = modal.querySelector('#confirmUseButton');
    
    modalItemName.textContent = itemName;
    
    // Set title and button text based on item type
    if (itemType === 'equipment') {
        modalTitle.textContent = 'Equip Item';
        confirmButton.textContent = 'Equip';
    } else if (itemType === 'boost') {
        modalTitle.textContent = 'Activate Boost';
        confirmButton.textContent = 'Activate';
    } else {
        modalTitle.textContent = 'Use Item';
        confirmButton.textContent = 'Use';
    }
    
    // Set confirmation action
    confirmButton.onclick = function() {
        onConfirm();
        // Hide modal after confirm
        const bsModal = bootstrap.Modal.getInstance(modal);
        bsModal.hide();
    };
    
    // Show the modal
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
}

/**
 * Create the use item confirmation modal
 */
function createUseItemModal() {
    const modal = document.createElement('div');
    modal.id = 'itemUseModal';
    modal.className = 'modal fade';
    modal.tabIndex = '-1';
    modal.setAttribute('aria-labelledby', 'itemUseModalLabel');
    modal.setAttribute('aria-hidden', 'true');
    
    modal.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="itemUseModalLabel">Use Item</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p>Are you sure you want to use <strong id="modalItemName"></strong>?</p>
                    <p>This action may be irreversible for consumable items.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" id="confirmUseButton" class="btn btn-primary">Use</button>
                </div>
            </div>
        </div>
    `;
    
    return modal;
}

/**
 * Send AJAX request to use an item
 */
function useItem(inventoryId) {
    // Show loading state
    const button = document.querySelector(`[data-inventory-id="${inventoryId}"]`);
    if (button) {
        const originalText = button.textContent;
        button.disabled = true;
        button.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Processing...';
    }

    fetch(`/marketplace/useItem/${inventoryId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            // Show success message
            showNotification('success', data.effect || data.message);
            
            // If it was a consumable, remove it from the UI
            if (data.itemType === 'consumable') {
                const itemElement = document.querySelector(`[data-inventory-id="${inventoryId}"]`).closest('.item-card');
                if (itemElement) {
                    itemElement.style.opacity = '0.5';
                    setTimeout(() => {
                        itemElement.remove();
                    }, 1000);
                }
            }
        } else {
            // Show error message
            showNotification('error', data.message || 'Failed to use item');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showNotification('error', 'Failed to process request. Please try again.');
    })
    .finally(() => {
        // Restore button state
        if (button) {
            button.disabled = false;
            button.textContent = originalText;
        }
    });
}

function showNotification(type, message) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show position-fixed top-0 end-0 m-3`;
    alertDiv.style.zIndex = '1050';
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        alertDiv.classList.remove('show');
        setTimeout(() => alertDiv.remove(), 150);
    }, 5000);
}

/**
 * Display the effect of using an item
 */
function showItemEffect(itemCard, effectText, itemType) {
    const effectDisplay = document.createElement('div');
    effectDisplay.className = 'alert alert-success mt-2 mb-0 text-center';
    effectDisplay.textContent = effectText || 'Item used successfully';
    
    // Add effect to card
    itemCard.appendChild(effectDisplay);
    
    // Remove after animation completes
    setTimeout(() => {
        effectDisplay.remove();
    }, 3000);
    
    // Also show a toast notification
    showToast('Success', effectText || 'Item used successfully');
}

/**
 * Show a toast notification
 */
function showToast(title, message) {
    // Check if toast container exists, create if not
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }
    
    // Create toast element
    const toastId = 'toast-' + Math.random().toString(36).substring(2, 9);
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.id = toastId;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');
    
    // Set header color based on title
    const headerClass = title.toLowerCase() === 'success' ? 'text-success' : 'text-danger';
    
    toast.innerHTML = `
        <div class="toast-header">
            <strong class="me-auto ${headerClass}">${title}</strong>
            <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body">
            ${message}
        </div>
    `;
    
    // Add to container
    toastContainer.appendChild(toast);
    
    // Initialize and show toast
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
    
    // Remove from DOM after hiding
    toast.addEventListener('hidden.bs.toast', function() {
        toast.remove();
    });
}
