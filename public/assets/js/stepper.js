/**
 * Stepper Component JavaScript
 * Handles multi-step form functionality for character creation
 */
$(function () {
  'use strict';

  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Constants
  const TOTAL_STEPS = 4;
  
  // Variables
  var $progressWizard = $('.stepper');
  var $progressBar = $('.progress-bar');
  var $btn_prev = $progressWizard.find('.prev-step');
  var $btn_next = $progressWizard.find('.next-step');
  var selectedAvatar = 1;

  // Initialize progress bar
  updateProgress(1);

  /**
   * Update progress bar and step indicators
   * @param {number} currentStep - Current step number
   */
  function updateProgress(currentStep) {
    // Calculate progress percentage
    var progressPercentage = ((currentStep - 1) / (TOTAL_STEPS - 1)) * 100;
    $progressBar.css('width', progressPercentage + '%');

    // Update step indicators
    $('.step-indicator').each(function () {
      var stepNumber = $(this).data('step');

      // Reset all classes first
      $(this).removeClass('active completed disabled');
      $(this).find('.step-dot').removeClass('active completed disabled');

      // Set appropriate class based on step number
      if (stepNumber < currentStep) {
        $(this).addClass('completed');
        $(this).find('.step-dot').addClass('completed');
      } else if (stepNumber === currentStep) {
        $(this).addClass('active');
        $(this).find('.step-dot').addClass('active');
      } else {
        $(this).addClass('disabled');
        $(this).find('.step-dot').addClass('disabled');
      }
    });
  }

  /**
   * Show a specific step
   * @param {number} stepNumber - Step number to show
   */
  function showStep(stepNumber) {
    // Hide all tab panes
    $('.tab-pane').removeClass('active');

    // Show the selected tab
    $('#stepper-step-' + stepNumber).addClass('active');

    // Update progress
    updateProgress(stepNumber);
    
    // Scroll to top for mobile
    $('html, body').animate({
      scrollTop: $progressWizard.offset().top - 30
    }, 300);
  }

  /**
   * Get current active step number
   * @returns {number} Current step
   */
  function getCurrentStep() {
    var currentId = $('.tab-pane.active').attr('id');
    return parseInt(currentId.split('-')[2]);
  }

  /**
   * Validate step 3 form inputs
   * @returns {boolean} True if valid, false otherwise
   */
  function validateStep3() {
    var username = $('#username').val();
    
    if (!username || username.length < 3) {
      $('#username').addClass('is-invalid');
      $('.invalid-feedback').show();
      return false;
    } 
    
    // Valid input
    $('#username').removeClass('is-invalid');
    $('.invalid-feedback').hide();
    
    // Update final screen
    $('#hero-name').text(username);
    $('#final-objective').text('Your quest: ' + 
      ($('#objective').val() || 'Become the best version of yourself'));
      
    return true;
  }

  // Make step indicators clickable
  $('.step-indicator').on('click', function () {
    var clickedStep = $(this).data('step');
    var currentStep = getCurrentStep();

    // Only allow clicking on completed steps or the next available step
    if (clickedStep <= currentStep || clickedStep === currentStep + 1) {
      // Form validation for step 3 if trying to move forward past it
      if (currentStep === 3 && clickedStep === 4) {
        if (!validateStep3()) return false;
      }

      showStep(clickedStep);
    }
  });

  // Handle next button click
  $btn_next.on('click', function () {
    var currentStep = getCurrentStep();

    // Form validation for step 3
    if (currentStep === 3) {
      if (!validateStep3()) return false;
    }

    // Move to next step
    if (currentStep < TOTAL_STEPS) {
      showStep(currentStep + 1);

      // Stats animation on final step
      if (currentStep + 1 === 4) {
        setTimeout(function () {
          $('#stepper-step-4 .stats-progress').first().css('width', '100%');
          $('#stepper-step-4 .stats-progress').last().css('width', '0%');
        }, 100);
      }
    }
  });

  // Handle previous button click
  $btn_prev.click(function () {
    var currentStep = getCurrentStep();
    if (currentStep > 1) {
      showStep(currentStep - 1);
    }
  });

  // Handle avatar selection
  $('.avatar-option').click(function () {
    $('.avatar-option').removeClass('selected');
    $(this).addClass('selected');

    // Update the preview
    selectedAvatar = $(this).data('avatar');
    var avatarIcon = $(this).html();
    $('.selected-avatar-display').html(avatarIcon);
    $('#final-avatar').html(avatarIcon);
    $('#avatar_id').val(selectedAvatar); // Update hidden form field
  });

  // Form submission validation
  $('#characterForm').on('submit', function (e) {
    var currentStep = getCurrentStep();
    
    // Only validate if we're on step 3
    if (currentStep === 3) {
      var username = $('#username').val();
      
      if (!username || username.length < 3) {
        e.preventDefault();
        $('#username').addClass('is-invalid');
        $('.invalid-feedback').show();
        return false;
      }
    }
    
    // Allow form submission
    return true;
  });
}); 