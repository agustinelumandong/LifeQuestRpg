document.addEventListener("DOMContentLoaded", function () {
  console.log("Modal script loaded");

  // Handle Edit Modal
  const editModal = document.getElementById("editTaskModal");
  if (editModal) {
    editModal.addEventListener("show.bs.modal", function (event) {
      console.log("Edit modal show event triggered");

      const button = event.relatedTarget;
      if (!button) {
        console.error("No button found as event.relatedTarget");
        return;
      }

      const taskId = button.getAttribute("data-task-id");
      const taskTitle = button.getAttribute("data-task-title");
      const taskCategory = button.getAttribute("data-task-category");
      const taskDifficulty = button.getAttribute("data-task-difficulty");
      const taskStatus = button.getAttribute("data-task-status");
      const formAction = button.getAttribute("data-form-action");

      console.log("Data from button:", {
        taskId,
        taskTitle,
        taskCategory,
        taskDifficulty,
        taskStatus,
        formAction,
      });

      // Set form field values
      const form = document.getElementById("editTaskForm");
      
      // Determine whether this is a good habit or bad habit
      let baseUrl = "/goodhabit/";
      if (window.location.pathname.includes("badhabit")) {
        baseUrl = "/badhabit/";
      } else if (formAction) {
        baseUrl = formAction + "/";
      }
      
      if (form) form.action = baseUrl + taskId;

      // Set form values
      const titleField = document.getElementById("edit-title");
      const categoryField = document.getElementById("edit-category");
      const difficultyField = document.getElementById("edit-difficulty");
      const statusField = document.getElementById("edit-status");
      
      if (titleField) titleField.value = taskTitle;
      if (categoryField) categoryField.value = taskCategory;
      if (difficultyField) difficultyField.value = taskDifficulty;
      if (statusField && taskStatus) statusField.value = taskStatus;

      // Set delete form action if it exists
      const deleteForm = document.getElementById("deleteHabitForm");
      if (deleteForm) {
        deleteForm.action = baseUrl + taskId + "/delete";
      }
    });
  } else {
    console.warn("Edit modal element not found");
  }

  // Handle direct delete confirmation modal
  const directDeleteModal = document.getElementById("directDeleteModal");
  if (directDeleteModal) {
    directDeleteModal.addEventListener("show.bs.modal", function (event) {
      console.log("Direct delete modal show event triggered");
      
      const button = event.relatedTarget;
      if (!button) {
        console.error("No button found as event.relatedTarget");
        return;
      }
      
      const habitId = button.getAttribute("data-habit-id");
      const habitTitle = button.getAttribute("data-habit-title");
      
      console.log("Delete data from button:", { habitId, habitTitle });
      
      // Determine whether this is a good habit or bad habit
      let baseUrl = "/goodhabit/";
      if (window.location.pathname.includes("badhabit")) {
        baseUrl = "/badhabit/";
      }
      
      // Set text and form action
      const titleElement = document.getElementById("habitTitleToDelete");
      const deleteForm = document.getElementById("directDeleteForm");
      
      if (titleElement) titleElement.textContent = habitTitle;
      if (deleteForm) deleteForm.action = baseUrl + habitId + "/delete";
    });
  } else {
    console.warn("Direct delete modal element not found");
  }

  // Reset create form when modal is hidden
  const createModalEl = document.getElementById("createTaskModal");
  if (createModalEl) {
    createModalEl.addEventListener("hidden.bs.modal", function (event) {
      const form = createModalEl.querySelector("#createTaskForm");
      if (form) {
        form.reset();
        console.log("Create Task form reset");
      } else {
        console.warn("Create task form not found inside the modal");
      }
    });
  } else {
    console.warn("Create modal element not found");
  }
});
