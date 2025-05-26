<div class="modal fade" id="exampleModalFullscreen" tabindex="-1" aria-labelledby="exampleModalFullscreenLabel"
  style="display: none;" aria-hidden="true">
  <div class="modal-dialog modal-fullscreen">
    <div class="modal-content" style="background-color: #f8f9fa;">
      <div class="modal-header" style="border:none; background-color: white;">
        <h5 class="modal-title" id="exampleModalFullscreenLabel"
          style="color: black; font-family: 'Pixelify Sans', sans-serif;">Focus Mode</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body pomodoro-modal-body">
        <div class="timer-view">
          <div class="pomodoro-container">
            <div class="btn-group pomodoro-btn-group mb-3" role="group" aria-label="Timer Modes">
              <button type="button" class="btn active">Pomodoro</button>
              <button type="button" class="btn">Short Break</button>
              <button type="button" class="btn">Long Break</button>
            </div>

            <h2 id="timer" class="pomodoro-timer-display">25:00</h2>

            <div class="pomodoro-controls mt-3">
              <button onclick="startTimer()" id="startButton" class="btn btn-dark btn-lg">Start</button>
              <button onclick="restartTimer()" id="resetButton" class="btn btn-secondary btn-lg">Reset</button>

            </div>
          </div>
        </div>
        <div id="edit-view" style="display:none;">
          <h3>Change Time</h3>
          <div class="mb-3 d-flex justify-content-center align-items-center">
            <input type="number" id="mTimeInput" class="form-control form-control-lg" min="1" value="25" />
            <span class=" middle-colon fw-bolder">:</span>
            <input type="number" id="sTimeInput" class="form-control form-control-lg" min="1" value="00" />
          </div>
          <div class="pomodoro-controls mt-3">
            <button onclick="saveNewTime()" class="btn btn-success btn-lg">Save</button>
            <button onclick="setDefaultTime()" class="btn btn-secondary btn-lg">Default</button>
            <button onclick="showTimerScreen()" class="btn btn-light btn-lg">Back</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>