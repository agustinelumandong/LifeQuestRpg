<div class="modal fade" id="directDeleteModal" tabindex="-1" aria-labelledby="directDeleteModalLabel"
  aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border border-dark">
      <div class="modal-header bg-white text-dark">
        <h5 class="modal-title" id="directDeleteModalLabel"><i class="bi bi-exclamation-triangle-fill me-2"></i>Delete
          Confirmation</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <p class="text-center fs-5">Are you sure you want to delete the habit: <br><strong
            id="habitTitleToDelete"></strong>?</p>
        <p class="text-center text-muted small">This action cannot be undone.</p>
      </div>
      <div class="modal-footer d-flex justify-content-center">
        <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">
          <i class="bi bi-x-circle me-1"></i>Cancel
        </button>
        <form id="directDeleteForm" method="post" action="">
          <input type="hidden" name="_method" value="DELETE">
          <button type="submit" class="btn btn-dark">
            <i class="bi bi-trash me-1"></i>Delete Permanently
          </button>
        </form>
      </div>
    </div>
  </div>
</div>