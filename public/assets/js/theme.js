/**
 * Theme switching functionality for LifeQuestRPG
 */
document.addEventListener('DOMContentLoaded', function() {
    // Get the saved theme preference from localStorage or from the user settings
    const savedTheme = localStorage.getItem('theme') || document.documentElement.getAttribute('data-bs-theme');
    const savedColorScheme = localStorage.getItem('colorScheme') || 'default';
    
    // If no saved theme, check system preference
    if (!savedTheme) {
        const prefersDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const systemTheme = prefersDarkMode ? 'dark' : 'light';
        applyTheme(systemTheme);
    } else {
        // Apply the saved theme
        applyTheme(savedTheme);
    }
    
    // Apply color scheme
    applyColorScheme(savedColorScheme);
    
    // Listen for system preference changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
        // Only apply system theme if no user preference is saved
        if (!localStorage.getItem('theme')) {
            const newTheme = event.matches ? 'dark' : 'light';
            applyTheme(newTheme);
        }
    });
    
    // Listen for theme settings form submission
    const themeForm = document.querySelector('#theme form');
    if (themeForm) {
        themeForm.addEventListener('submit', function(e) {
            // Get the selected theme value
            const themeInputs = document.querySelectorAll('input[name="theme"]');
            let selectedTheme = 'light'; // Default theme
            
            themeInputs.forEach(input => {
                if (input.checked) {
                    selectedTheme = input.value;
                }
            });
            
            // Get selected color scheme
            const colorSchemeSelect = document.getElementById('colorScheme');
            const selectedColorScheme = colorSchemeSelect ? colorSchemeSelect.value : 'default';
            
            // Save the preferences to localStorage
            localStorage.setItem('theme', selectedTheme);
            localStorage.setItem('colorScheme', selectedColorScheme);
            
            // Apply the theme
            applyTheme(selectedTheme);
            applyColorScheme(selectedColorScheme);
        });
    }
    
    // Listen for immediate theme switching when radio buttons are clicked
    const themeRadios = document.querySelectorAll('input[name="theme"]');
    themeRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            if (this.checked) {
                // Save the theme preference to localStorage
                localStorage.setItem('theme', this.value);
                
                // Apply the theme immediately
                applyTheme(this.value);
            }
        });
    });
    
    // Handle color scheme change
    const colorSelect = document.getElementById('colorScheme');
    if (colorSelect) {
        colorSelect.value = savedColorScheme;
        
        colorSelect.addEventListener('change', function() {
            applyColorScheme(this.value);
        });
    }

    // Add event listeners to navbar theme switcher
    const themeOptions = document.querySelectorAll('.theme-switch-option');
    themeOptions.forEach(option => {
        option.addEventListener('click', function(e) {
            e.preventDefault();
            const theme = this.getAttribute('data-theme');
            applyTheme(theme);
            
            // If user is logged in, save preference to server
            if (typeof updateUserThemePreference === 'function') {
                updateUserThemePreference(theme);
            }
        });
    });

    // Add hover preview effect to theme options
    const themePreviewOptions = document.querySelectorAll('.theme-option');
    if (themePreviewOptions.length > 0) {
        // Get the currently active theme
        const activeTheme = localStorage.getItem('theme') || 
                          document.documentElement.getAttribute('data-bs-theme') || 
                          'light';
        
        // Add data-theme attribute to each option
        themePreviewOptions.forEach(option => {
            const themeInput = option.querySelector('input[name="theme"]');
            if (themeInput) {
                const themeValue = themeInput.value;
                option.setAttribute('data-theme', themeValue);
                
                // Add hover effect
                option.addEventListener('mouseenter', function() {
                    previewTheme(themeValue);
                });
                
                // Add click effect for immediate preview
                option.addEventListener('click', function() {
                    document.querySelectorAll('input[name="theme"]').forEach(input => {
                        if (input.value === themeValue) {
                            input.checked = true;
                            applyTheme(themeValue);
                        }
                    });
                });
            }
        });
        
        // Reset preview when mouse leaves the theme selection area
        const themeContainer = themePreviewOptions[0].closest('.row');
        if (themeContainer) {
            themeContainer.addEventListener('mouseleave', function() {
                const currentTheme = document.querySelector('input[name="theme"]:checked').value;
                previewTheme(currentTheme);
            });
        }
    }

    // Listen for color scheme changes for preview
    const colorSchemeSelect = document.getElementById('colorScheme');
    if (colorSchemeSelect) {
        // Initial value
        const initialScheme = colorSchemeSelect.value;
        
        // Show preview on focus
        colorSchemeSelect.addEventListener('focus', function() {
            // Store the initial value to restore if canceled
            colorSchemeSelect.dataset.initialValue = colorSchemeSelect.value;
        });
        
        // Update preview on change
        colorSchemeSelect.addEventListener('change', function() {
            applyColorScheme(this.value);
        });
        
        // Add colored indicators to the select options
        // This needs to be done after the DOM is fully loaded
        setTimeout(() => {
            // Try to enhance the select with color indicators if possible
            try {
                const colorOptions = colorSchemeSelect.options;
                for (let i = 0; i < colorOptions.length; i++) {
                    const option = colorOptions[i];
                    const colorValue = option.value;
                    
                    // Add color dot to option text if not already present
                    if (!option.innerHTML.includes('color-dot')) {
                        const colorClass = `color-dot color-${colorValue}-dot`;
                        option.innerHTML = `<span class="${colorClass}"></span> ${option.text}`;
                    }
                }
            } catch (e) {
                console.log("Color scheme select enhancement failed", e);
            }
        }, 500);
    }

    // Initialize mobile theme toggle button
    const mobileToggle = document.getElementById('mobileThemeToggle');
    if (mobileToggle) {
        mobileToggle.addEventListener('click', function() {
            const currentTheme = document.documentElement.getAttribute('data-bs-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            
            // Apply the theme
            applyTheme(newTheme);
            
            // If user is logged in, save preference to server
            if (typeof updateUserThemePreference === 'function' && document.body.classList.contains('logged-in')) {
                updateUserThemePreference(newTheme);
            }
            
            // Add a small animation effect
            this.classList.add('theme-toggled');
            setTimeout(() => {
                this.classList.remove('theme-toggled');
            }, 500);
        });
        
        // Update button icon based on current theme
        updateMobileToggleIcon();
    }
});

/**
 * Apply the specified theme to the document
 * 
 * @param {string} theme - The theme to apply ('light' or 'dark')
 */
function applyTheme(theme) {
    // Set the data-bs-theme attribute on the html element
    document.documentElement.setAttribute('data-bs-theme', theme);
    
    // Also update body classes for custom styling
    document.body.classList.remove('theme-light', 'theme-dark');
    document.body.classList.add('theme-' + theme);

    // Save to localStorage
    localStorage.setItem('theme', theme);

    // Update the theme selection in the settings form
    const themeRadio = document.querySelector(`input[name="theme"][value="${theme}"]`);
    if (themeRadio) {
        themeRadio.checked = true;
        
        // Update theme option UI
        const themeOptions = document.querySelectorAll('.theme-option');
        if (themeOptions.length > 0) {
            // Remove border-primary from all theme options
            themeOptions.forEach(option => {
                option.classList.remove('border-primary');
            });
            
            // Add border-primary to selected theme option
            const selectedOption = themeRadio.closest('.theme-option');
            if (selectedOption) {
                selectedOption.classList.add('border-primary');
            }
        }
    }
    
    // Update any navbar theme switcher dropdowns
    highlightActiveThemeInNavbar(theme);
    
    // Update mobile toggle button icon
    updateMobileToggleIcon();
}

/**
 * Highlight active theme in navbar dropdown
 * @param {string} theme - The active theme
 */
function highlightActiveThemeInNavbar(theme) {
    const navbarThemeOptions = document.querySelectorAll('.theme-switch-option');
    navbarThemeOptions.forEach(option => {
        // Remove active class from all options
        option.classList.remove('active');
        
        // Add active class to current theme
        if (option.getAttribute('data-theme') === theme) {
            option.classList.add('active');
        }
    });
}

/**
 * Apply the selected color scheme
 * @param {string} colorScheme - Color scheme name
 * @param {boolean} previewOnly - If true, only updates preview elements
 */
function applyColorScheme(colorScheme, previewOnly = false) {
    if (!previewOnly) {
        document.body.classList.remove('color-default', 'color-forest', 'color-ocean', 'color-sunset');
        document.body.classList.add('color-' + colorScheme);
        
        // Save to localStorage
        localStorage.setItem('colorScheme', colorScheme);
        
        // Update the color scheme selection in the settings form
        const colorSchemeSelect = document.getElementById('colorScheme');
        if (colorSchemeSelect) {
            colorSchemeSelect.value = colorScheme;
        }
    }
    
    // Update preview elements if they exist
    updateColorSchemePreview(colorScheme);
}

/**
 * Update color scheme preview elements
 * @param {string} colorScheme - Color scheme to preview
 */
function updateColorSchemePreview(colorScheme) {
    // Get all preview elements that should change based on color scheme
    const previewElements = document.querySelectorAll('.color-preview-element');
    
    // Remove all color classes first
    previewElements.forEach(element => {
        element.classList.remove('color-default-preview', 'color-forest-preview', 
                              'color-ocean-preview', 'color-sunset-preview');
        element.classList.add('color-' + colorScheme + '-preview');
    });
}

/**
 * Helper function to preview themes without changing the actual theme
 * @param {string} theme - The theme to preview
 */
function previewTheme(theme) {
    const themePreviewOptions = document.querySelectorAll('.theme-option');
    
    themePreviewOptions.forEach(option => {
        // Reset all previews
        option.classList.remove('border-primary');
    });
    
    // Highlight current preview
    const selectedOption = document.querySelector(`.theme-option[data-theme="${theme}"]`);
    if (selectedOption) {
        selectedOption.classList.add('border-primary');
    }
}

/**
 * Update the mobile toggle button icon based on current theme
 */
function updateMobileToggleIcon() {
    const mobileToggle = document.getElementById('mobileThemeToggle');
    if (!mobileToggle) return;
    
    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
    const iconElement = mobileToggle.querySelector('i');
    
    if (iconElement) {
        // Remove existing icon classes
        iconElement.classList.remove('fa-sun-o', 'fa-moon-o', 'fa-adjust');
        
        // Add appropriate icon based on current theme
        if (currentTheme === 'dark') {
            iconElement.classList.add('fa-moon-o');
        } else if (currentTheme === 'light') {
            iconElement.classList.add('fa-sun-o');
        } else {
            iconElement.classList.add('fa-adjust');
        }
    }
}
