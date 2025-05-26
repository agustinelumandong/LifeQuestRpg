  let timer;
  let minutes = 25;
  let seconds = 0;
  let isPaused = false;
  let enteredTime = null;



  function startTimer() {
    const startButton = document.getElementById("startButton");

    if (startButton.textContent === "Start" || startButton.textContent === "Resume") {
      startButton.textContent = "Pause";
      clearInterval(timer);

      timer = setInterval(() => {
        if (seconds === 0) {
          if (minutes === 0) {
            clearInterval(timer);
            alert("Time's up!");
            return;
          }
          minutes--;
          seconds = 59;
        } else {
          seconds--;
        }
        updateDisplay();
      }, 1000);

    } else if (startButton.textContent === "Pause") {
      clearInterval(timer);
      startButton.textContent = "Resume";
    }
  }

  function updateDisplay() {
    const timerElement = document.getElementById("timer");
    timerElement.textContent = formatTime(minutes, seconds);
  }

  function formatTime(minutes, seconds) {
    return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  function togglePauseResume() {
    const pauseResumeButton = document.querySelector('.control-buttons button');
    isPaused = !isPaused;

    if (isPaused) {
      clearInterval(timer);
      pauseResumeButton.textContent = "Resume";
    } else {
      startTimer();
      pauseResumeButton.textContent = "Pause";
    }
  }

  function restartTimer() {
    clearInterval(timer);

    const activeMode = document.querySelector('.pomodoro-btn-group .active');
    if (enteredTime) {
      minutes = enteredTime;
    } else if (activeMode && activeMode.textContent.includes("Pomodoro")) {
      minutes = 25;
    } else if (activeMode && activeMode.textContent.includes("Short Break")) {
      minutes = 5;
    } else if (activeMode && activeMode.textContent.includes("Long Break")) {
      minutes = 15;
    }


    seconds = 0;
    isPaused = false;
    updateDisplay();

    // const timerElement = document.getElementById('timer');
    // timerElement.textContent = formatTime(minutes, seconds);
    // const pauseResumeButton = document.querySelector('.control-buttons button');
    // pauseResumeButton.textContent = 'Pause';
    // startTimer();
    document.getElementById("startButton").textContent = "Start";
  }

  function chooseTime() {
    const newTime = prompt('Enter new time in minutes:');
    if (!isNaN(newTime) && newTime > 0) {
      enteredTime = parseInt(newTime);
      minutes = enteredTime;
      seconds = 0;
      isPaused = false;
      updateDisplay();
      clearInterval(timer);
    } else {
      alert('Invalid input. Please enter' +
        ' a valid number greater than 0.');
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    updateDisplay();
    const modeButtons = document.querySelectorAll('.pomodoro-btn-group .btn');
    modeButtons.forEach(button => {
      button.addEventListener('click', function () {
        modeButtons.forEach(btn => btn.classList.remove('active'));
        this.classList.add('active');

        if (this.textContent.includes("Pomodoro")) {
          minutes = 25;
        } else if (this.textContent.includes("Short Break")) {
          minutes = 5;
        } else if (this.textContent.includes("Long Break")) {
          minutes = 15;
        }
        seconds = 0;
        updateDisplay();
        clearInterval(timer);

        document.getElementById("startButton").textContent = "Start";
      });
    });
  });

  // edit mode
  function showEditScreen() {
    document.querySelector('.timer-view').style.display = 'none';
    document.getElementById('edit-view').style.display = 'block';

    const mInput = document.getElementById('mTimeInput');
    const sInput = document.getElementById('sTimeInput');

    // Set initial values, ensuring they are padded to 2 digits
    mInput.value = String(minutes).padStart(2, '0');
    sInput.value = String(seconds).padStart(2, '0');

    // Set min/max values for validation
    mInput.min = 1; // Minimum minutes
    mInput.max = 99; // Maximum minutes (2 digits)
    sInput.min = 0; // Minimum seconds
    sInput.max = 59; // Maximum seconds (2 digits)

    // Set maxlength attribute to limit visual input length to 2 characters
    mInput.maxLength = 2;
    sInput.maxLength = 2;
  }

  function showTimerScreen() {
    document.querySelector('.timer-view').style.display = 'block';
    document.getElementById('edit-view').style.display = 'none';
  }

  function saveNewTime() {
    const newMinutesTime = parseInt(document.getElementById('mTimeInput').value);
    const newSecondsTime = parseInt(document.getElementById('sTimeInput').value);

    if (newMinutesTime < 0 || newSecondsTime < 0) {
      alert('Invalid input. Please enter a valid number greater than or equal to 0.');
    } else {
      enteredTime = newMinutesTime;
      minutes = newMinutesTime;
      seconds = newSecondsTime;
      updateDisplay();
      showTimerScreen();
    }
  }

  function setDefaultTime() {
    const activeMode = document.querySelector('.pomodoro-btn-group .active');
    let defaultTime = 25;

    if (activeMode.textContent.includes("Short Break")) {
      defaultTime = 5;
    } else if (activeMode.textContent.includes("Long Break")) {
      defaultTime = 15;
    }

    document.getElementById('mTimeInput').value = defaultTime;
    document.getElementById('sTimeInput').value = 0;
  }