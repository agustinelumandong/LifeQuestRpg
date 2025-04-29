document.addEventListener("DOMContentLoaded", function () {
  console.log("Modal script loaded");

  const editModal = document.getElementById("editTaskModal");
  if (!editModal) {
    console.error("Edit modal element not found");
    return;
  }

  if (typeof bootstrap !== "undefined") {
    editModal.addEventListener("show.bs.modal", function (event) {
      console.log("Modal show event triggered");

      const button = event.relatedTarget;
      if (!button) {
        console.error("No button found as event.relatedTarget");
        return;
      }

      const taskId = button.getAttribute("data-task-id");
      const taskTitle = button.getAttribute("data-task-title");
      const taskCategory = button.getAttribute("data-task-category");
      const taskDifficulty = button.getAttribute("data-task-difficulty");
      const formAction = button.getAttribute("data-form-action");

      console.log("Data from button:", {
        taskId,
        taskTitle,
        taskCategory,
        taskDifficulty,
        formAction,
      });

      // Set form field values
      const form = document.getElementById("editTaskForm");
      const idField = document.getElementById("edit-task-id");
      const titleField = document.getElementById("edit-title");
      const categoryField = document.getElementById("edit-category");
      const difficultyField = document.getElementById("edit-difficulty");

      if (form && formAction) form.action = formAction + "/" + taskId;
      if (idField) idField.value = taskId;
      if (titleField) titleField.value = taskTitle;
      if (categoryField) categoryField.value = taskCategory;
      if (difficultyField) difficultyField.value = taskDifficulty;
    });
    
  } else {
    console.error("Bootstrap not loaded");
  }

  const createModalEl = document.getElementById("createTaskModal");
  if (createModalEl) {
    createModalEl.addEventListener("hidden.bs.modal", function (event) {
      const form = createModalEl.querySelector("#createTaskForm");
      if (form) {
        form.reset();
        console.log("Create Task form reset");
      } else {
        console.error(
          "Create task form ('createTaskForm') not found inside the modal."
        );
      }
    });
  } else {
    console.warn("Create modal element ('createTaskModal') not found.");
  }
});
