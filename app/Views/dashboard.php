<div class="container">
  <div class="row">
    <!-- Left Panel - Character Profile -->
    <div class="col-md-3 col-lg-3 mb-4">
      <div class="profile-panel p-3 mb-4">
        <!-- Character Avatar -->
        <div class="text-center mb-3">
          <div class="profile-avatar bg-white text-dark mb-2">
            <img
              src="https://scontent.fdvo1-1.fna.fbcdn.net/v/t39.30808-6/485731303_122192114528146689_1646769985247999596_n.jpg?_nc_cat=109&ccb=1-7&_nc_sid=833d8c&_nc_eui2=AeFqlYUeQuH3XhEFa-F_IC2DxFbuykcGBYfEVu7KRwYFh-x8ZHhi7jfikIj9aGc2DAo-M9AXUMEBQvHoZ1tNPreM&_nc_ohc=yC6a8goFbGkQ7kNvwGrcYef&_nc_oc=AdkbF7z9OJ_Q1xfR9ID44E8nK6jSzfBBeIX8-tfXJsJ-WxEpSwIrHxwJSycA18YDpfE&_nc_zt=23&_nc_ht=scontent.fdvo1-1.fna&_nc_gid=-giwK5A7k-48BycBQX14qA&oh=00_AfH4Jjm0t25BFLpT74zNeWjo0a1yoHrzBCFsaoPuUHc20Q&oe=680690D7"
              alt="Character Avatar" class="img-fluid rounded-circle">
          </div>
          <h4 class="mb-0" style="font-family: 'Pixelify Sans', serif;">BRADER SEAN</h4>
          <div class="badge bg-dark">Level 2</div>
        </div>

        <!-- Health Bar -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span><i class="bi bi-heart-fill"></i> Health</span>
            <span class="badge bg-dark">80/100</span>
          </div>
          <div class="progress">
            <div class="progress-bar bg-dark" role="progressbar" style="width: 80%" aria-valuenow="80" aria-valuemin="0"
              aria-valuemax="100"></div>
          </div>
        </div>

        <!-- Goal Completion -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-flag-fill"></i> Goal
              Completion</span>
            <span class="badge bg-dark">10%</span>
          </div>
          <div class="progress">
            <div class="progress-bar bg-dark" role="progressbar" style="width: 10%" aria-valuenow="10" aria-valuemin="0"
            aria-valuemax="100"></div>
          </div>
        </div>

        <!-- Level Progress -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-arrow-up-circle"></i>
              Level UP</span>
            <span class="badge bg-dark">10/100</span>
          </div>
          <div class="progress">
            <div class="progress-bar bg-dark" role="progressbar" style="width: 10%" aria-valuenow="10" aria-valuemin="0"
              aria-valuemax="100"></div>
          </div>
        </div>
      </div>

      <!-- POMODORO TIMER -->
      <div class="pomodoro-panel mb-4">
        <h5 class="border-bottom pb-2 mb-3 " style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-alarm me-2"></i> Pomodoro Timer
        </h5>
        <div class="d-flex flex-column align-items-center justify-content-center mb-3">
          <h1 class="fw-bold text-center" style="font-family: 'Pixelify Sans', serif;">24:00</h1>
          <!-- <a href="#" class="focus-btn text-white ">FOCUS MODE</a> -->
          <button type="button" type="button" class="btn focus-btn text-white" data-bs-toggle="modal"
            data-bs-target="#exampleModalFullscreen"> FOCUS
            MODE</button>

        </div>
      </div>
      <div class="spotify-panel">
        <iframe class="spotify" id="spotify"
          src="https://open.spotify.com/embed/playlist/4Zjli1P13J5mmSCD5iKAXK?theme=0" width="100%" height="80"
          frameborder="0" allowtransparency="true"
          allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy">
        </iframe>
      </div>
    </div>

    <!-- Middle Panel - RPG Content -->
    <div class="col-md-6 col-lg-6 mb-4">
      <div class="card mb-4">
        <div class="card-header bg-white">
          <h2 class="text-center my-2" style="font-family: 'Pixelify Sans', serif;">
            <i class="bi bi-controller"></i> Welcome To Life RPG
          </h2>
        </div>

        <div class="card-body">
          <!-- Habit Grid -->
          <div class="row g-4 justify-content-center">
            <!-- Row 1: Good Habits -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <i class="fas fa-cross mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Good Habits</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <i class="fas fa-skull-crossbones mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Bad Habits</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <i class="fas fa-trophy mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Achivements</p>
              </a>
            </div>

            <!-- Row 2: Good Habits -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -64 640 640" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M560 160A80 80 0 1 0 560 0a80 80 0 1 0 0 160zM55.9 512H381.1h75H578.9c33.8 0 61.1-27.4 61.1-61.1c0-11.2-3.1-22.2-8.9-31.8l-132-216.3C495 196.1 487.8 192 480 192s-15 4.1-19.1 10.7l-48.2 79L286.8 81c-6.6-10.6-18.3-17-30.8-17s-24.1 6.4-30.8 17L8.6 426.4C3 435.3 0 445.6 0 456.1C0 487 25 512 55.9 512z">
                  </path>
                </svg>
                <p class="habit-label">Inventory</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -32 576 576" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M547.6 103.8L490.3 13.1C485.2 5 476.1 0 466.4 0H109.6C99.9 0 90.8 5 85.7 13.1L28.3 103.8c-29.6 46.8-3.4 111.9 51.9 119.4c4 .5 8.1 .8 12.1 .8c26.1 0 49.3-11.4 65.2-29c15.9 17.6 39.1 29 65.2 29c26.1 0 49.3-11.4 65.2-29c15.9 17.6 39.1 29 65.2 29c26.2 0 49.3-11.4 65.2-29c16 17.6 39.1 29 65.2 29c4.1 0 8.1-.3 12.1-.8c55.5-7.4 81.8-72.5 52.1-119.4zM499.7 254.9l-.1 0c-5.3 .7-10.7 1.1-16.2 1.1c-12.4 0-24.3-1.9-35.4-5.3V384H128V250.6c-11.2 3.5-23.2 5.4-35.6 5.4c-5.5 0-11-.4-16.3-1.1l-.1 0c-4.1-.6-8.1-1.3-12-2.3V384v64c0 35.3 28.7 64 64 64H448c35.3 0 64-28.7 64-64V384 252.6c-4 1-8 1.8-12.3 2.3z">
                  </path>
                </svg>
                <p class="habit-label">Marketplace</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M0 96C0 43 43 0 96 0H384h32c17.7 0 32 14.3 32 32V352c0 17.7-14.3 32-32 32v64c17.7 0 32 14.3 32 32s-14.3 32-32 32H384 96c-53 0-96-43-96-96V96zM64 416c0 17.7 14.3 32 32 32H352V384H96c-17.7 0-32 14.3-32 32zm90.4-234.4l-21.2-21.2c-3 10.1-5.1 20.6-5.1 31.6c0 .2 0 .5 .1 .8s.1 .5 .1 .8L165.2 226c2.5 2.1 3.4 5.8 2.3 8.9c-1.3 3-4.1 5.1-7.5 5.1c-1.9-.1-3.8-.8-5.2-2l-23.6-20.6C142.8 267 186.9 304 240 304s97.3-37 108.9-86.6L325.3 238c-1.4 1.2-3.3 2-5.3 2c-2.2-.1-4.4-1.1-6-2.8c-1.2-1.5-1.9-3.4-2-5.2c.1-2.2 1.1-4.4 2.8-6l37.1-32.5c0-.3 0-.5 .1-.8s.1-.5 .1-.8c0-11-2.1-21.5-5.1-31.6l-21.2 21.2c-3.1 3.1-8.1 3.1-11.3 0s-3.1-8.1 0-11.2l26.4-26.5c-8.2-17-20.5-31.7-35.9-42.6c-2.7-1.9-6.2 1.4-5 4.5c8.5 22.4 3.6 48-13 65.6c-3.2 3.4-3.6 8.9-.9 12.7c9.8 14 12.7 31.9 7.5 48.5c-5.9 19.4-22 34.1-41.9 38.3l-1.4-34.3 12.6 8.6c.6 .4 1.5 .6 2.3 .6c1.5 0 2.7-.8 3.5-2s.6-2.8-.1-4L260 225.4l18-3.6c1.8-.4 3.1-2.1 3.1-4s-1.4-3.5-3.1-3.9l-18-3.7 8.5-14.3c.8-1.2 .9-2.9 .1-4.1s-2-2-3.5-2l-.1 0c-.7 .1-1.5 .3-2.1 .7l-14.1 9.6L244 87.9c-.1-2.2-1.9-3.9-4-3.9s-3.9 1.6-4 3.9l-4.6 110.8-12-8.1c-1.5-1.1-3.6-.9-5 .4s-1.6 3.4-.8 5l8.6 14.3-18 3.7c-1.8 .4-3.1 2-3.1 3.9s1.4 3.6 3.1 4l18 3.8-8.6 14.2c-.2 .6-.5 1.4-.5 2c0 1.1 .5 2.1 1.2 3c.8 .6 1.8 1 2.8 1c.7 0 1.6-.2 2.2-.6l10.4-7.1-1.4 32.8c-19.9-4.1-36-18.9-41.9-38.3c-5.1-16.6-2.2-34.4 7.6-48.5c2.7-3.9 2.3-9.3-.9-12.7c-16.6-17.5-21.6-43.1-13.1-65.5c1.2-3.1-2.3-6.4-5-4.5c-15.3 10.9-27.6 25.6-35.8 42.6l26.4 26.5c3.1 3.1 3.1 8.1 0 11.2s-8.1 3.1-11.2 0z">
                  </path>
                </svg>
                <p class="habit-label">AMVOT</p>
              </a>
            </div>

            <!-- Row 3: AMBOT -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M152 88a72 72 0 1 1 144 0A72 72 0 1 1 152 88zM39.7 144.5c13-17.9 38-21.8 55.9-8.8L131.8 162c26.8 19.5 59.1 30 92.2 30s65.4-10.5 92.2-30l36.2-26.4c17.9-13 42.9-9 55.9 8.8s9 42.9-8.8 55.9l-36.2 26.4c-13.6 9.9-28.1 18.2-43.3 25V288H128V251.7c-15.2-6.7-29.7-15.1-43.3-25L48.5 200.3c-17.9-13-21.8-38-8.8-55.9zm89.8 184.8l60.6 53-26 37.2 24.3 24.3c15.6 15.6 15.6 40.9 0 56.6s-40.9 15.6-56.6 0l-48-48C70 438.6 68.1 417 79.2 401.1l50.2-71.8zm128.5 53l60.6-53 50.2 71.8c11.1 15.9 9.2 37.5-4.5 51.2l-48 48c-15.6 15.6-40.9 15.6-56.6 0s-15.6-40.9 0-56.6L284 419.4l-26-37.2z">
                  </path>
                </svg>
                <p class="habit-label">AMBOT</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M352 0c53 0 96 43 96 96V416c0 53-43 96-96 96H64 32c-17.7 0-32-14.3-32-32s14.3-32 32-32V384c-17.7 0-32-14.3-32-32V32C0 14.3 14.3 0 32 0H64 352zm0 384H96v64H352c17.7 0 32-14.3 32-32s-14.3-32-32-32zM138.7 208l13.9 24H124.9l13.9-24zm-13.9-24L97.1 232c-6.2 10.7 1.5 24 13.9 24h55.4l27.7 48c6.2 10.7 21.6 10.7 27.7 0l27.7-48H305c12.3 0 20-13.3 13.9-24l-27.7-48 27.7-48c6.2-10.7-1.5-24-13.9-24H249.6L221.9 64c-6.2-10.7-21.6-10.7-27.7 0l-27.7 48H111c-12.3 0-20 13.3-13.9 24l27.7 48zm27.7 0l27.7-48h55.4l27.7 48-27.7 48H180.3l-27.7-48zm0-48l-13.9 24-13.9-24h27.7zm41.6-24L208 88l13.9 24H194.1zm69.3 24h27.7l-13.9 24-13.9-24zm13.9 72l13.9 24H263.4l13.9-24zm-55.4 48L208 280l-13.9-24h27.7z">
                  </path>
                </svg>
                <p class="habit-label">AMBOT</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="#" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M352 0c53 0 96 43 96 96V416c0 53-43 96-96 96H64 32c-17.7 0-32-14.3-32-32s14.3-32 32-32V384c-17.7 0-32-14.3-32-32V32C0 14.3 14.3 0 32 0H64 352zm0 384H96v64H352c17.7 0 32-14.3 32-32s-14.3-32-32-32zM274.1 150.2l-8.9 21.4-23.1 1.9c-5.7 .5-8 7.5-3.7 11.2L256 199.8l-5.4 22.6c-1.3 5.5 4.7 9.9 9.6 6.9L280 217.2l19.8 12.1c4.9 3 10.9-1.4 9.6-6.9L304 199.8l17.6-15.1c4.3-3.7 2-10.8-3.7-11.2l-23.1-1.9-8.9-21.4c-2.2-5.3-9.6-5.3-11.8 0zM96 192c0 70.7 57.3 128 128 128c25.6 0 49.5-7.5 69.5-20.5c3.2-2.1 4.5-6.2 3.1-9.7s-5.2-5.6-9-4.8c-6.1 1.2-12.5 1.9-19 1.9c-52.4 0-94.9-42.5-94.9-94.9s42.5-94.9 94.9-94.9c6.5 0 12.8 .7 19 1.9c3.8 .8 7.5-1.3 9-4.8s.2-7.6-3.1-9.7C273.5 71.5 249.6 64 224 64C153.3 64 96 121.3 96 192z">
                  </path>
                </svg>
                <p class="habit-label">AMBOT</p>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Panel - Activities & Quests -->
    <div class="col-md-3 col-lg-3">
      <!-- Activity Logs -->
      <div class="activity-panel mb-4">
        <h5 class="d-flex align-items-center border-bottom pb-2 mb-3" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-activity me-2"></i> Activities
        </h5>

        <div class="activity-item">
          <div class="activity-dot"></div>
          <div class="small text-muted mb-1">Today 10:45 PM</div>
          <div class="activity-details small">
            <div>You gained <strong>100 EXP</strong> and <strong>100 Coins</strong> in Taking a course!
            </div>
            <div class="text-success mt-1">+ 100 EXP & 100 Coins!</div>
          </div>
        </div>

        <div class="activity-item">
          <div class="activity-dot"></div>
          <div class="small text-muted mb-1">Today 09:30 PM</div>
          <div class="activity-details small">
            <div>You gained <strong>100 EXP</strong> and <strong>100 Coins</strong> in Taking a course!
            </div>
            <div class="text-success mt-1">+ 100 EXP & 100 Coins!</div>
          </div>
        </div>
      </div>

      <!-- Community Quests -->
      <div class="quest-panel">
        <h5 class="border-bottom pb-2 mb-3" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-map me-2"></i> Community Quests
        </h5>
        <a href="#" class="event-card-btn">
          <div class="event-card">
            <div class="fw-bold mb-1" style="font-family: 'Pixelify Sans', serif;">
              <i class="bi bi-joystick"></i> Quest 1
            </div>
            <div class="small text-muted">
              <div>Apr 10 - Apr 15, 2023</div>
            </div>
            <div class="d-flex mt-2">
              <div class="me-3 small">
                <i class="bi bi-stars"></i> 0 XP
              </div>
              <div class="small">
                <i class="bi bi-coin"></i> 10 Coins
              </div>
            </div>

          </div>
        </a>
        <a href="#" class="event-card-btn">
          <div class="event-card">
            <div class="fw-bold mb-1" style="font-family: 'Pixelify Sans', serif;">
              <i class="bi bi-joystick"></i> Quest 2
            </div>
            <div class="small text-muted">
              <div>Apr 10 - Apr 15, 2023</div>
            </div>
            <div class="d-flex mt-2">
              <div class="me-3 small">
                <i class="bi bi-stars"></i> 0 XP
              </div>
              <div class="small">
                <i class="bi bi-coin"></i> 10 Coins
              </div>
            </div>

          </div>
        </a>
        <a href="#" class="event-card-btn">
          <div class="event-card">
            <div class="fw-bold mb-1" style="font-family: 'Pixelify Sans', serif;">
              <i class="bi bi-joystick"></i> Quest 3
            </div>
            <div class="small text-muted">
              <div>Apr 10 - Apr 15, 2023</div>
            </div>
            <div class="d-flex mt-2">
              <div class="me-3 small">
                <i class="bi bi-stars"></i> 0 XP
              </div>
              <div class="small">
                <i class="bi bi-coin"></i> 10 Coins
              </div>
            </div>

          </div>
        </a>

      </div>
    </div>
  </div>
</div>

<style>
  .bs-icon {
    --bs-icon-size: .75rem;
    display: flex;
    flex-shrink: 0;
    justify-content: center;
    align-items: center;
    font-size: var(--bs-icon-size);
    width: calc(var(--bs-icon-size) * 2);
    height: calc(var(--bs-icon-size) * 2);
    color: var(--bs-primary);
  }

  .bs-icon-rounded {
    border-radius: .5rem;
  }

  .bs-icon-primary {
    color: #fff;
    background: #212529;
  }

  .card {
    border: 1px solid #212529;
    border-radius: 8px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
  }

  .card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
  }

  .habit-box {
    border-radius: 6px;
    border: 1px solid #212529;
    width: 200px;
    height: 200px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    background-color: white;
    text-decoration: none;
    color: #343A40;
  }

  .habit-box:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
  }

  .habit-icon {
    font-size: 80px;
    color: #212529;
    margin-bottom: 15px;
  }

  .habit-label {
    font-family: 'Pixelify Sans', serif;
    font-weight: bold;
    margin: 0;
  }

  .profile-panel {
    background-color: white;
    border: 1px solid #212529;
    border-radius: 8px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease;
    /* height: 100%; */
  }

  .profile-panel:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
  }

  .profile-avatar {
    width: 120px;
    height: 120px;
    background-size: cover;
    background-position: center;
    overflow: hidden;
    border-radius: 50%;
    margin: 0 auto;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .stat-box {
    transition: transform 0.2s;
    border: 1px solid #212529;
    border-radius: 6px;
    padding: 10px;
    margin-bottom: 10px;
    background-color: white;
  }

  .stat-box:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .pomodoro-panel {
    background-color: white;
    border: 1px solid #212529;
    padding: 15px;
    border-radius: 8px;
    box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease;
  }

  .pomodoro-panel:hover {
    transform: translateY(-5px);
    box-shadow: 0px 5px 15px tgba(0, 0, 0, 0.15);
  }

  .spotify {
    border: none;
    border-radius: 12px;
    box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease;
  }

  .spotify:hover {
    transform: translateY(-5px);
    box-shadow: 0px 5px 15px rgba(0, 0, 0, 0.15);
  }

  .focus-btn {
    background-color: #212529;
    color: white;
    border: none;
    text-decoration: none;
    padding: 10px 20px;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.3s ease, transform 0.2s ease;
  }

  .focus-btn:hover {
    background-color: #343A40;
    transform: translateY(-2px);
  }

  .activity-panel {
    background-color: white;
    border: 1px solid #212529;
    border-radius: 8px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease;
    padding: 15px;
    margin-bottom: 20px;
  }

  .activity-panel:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
  }

  .activity-timeline {
    position: relative;
  }

  .activity-item {
    padding: 10px;
    border-left: 3px solid #212529;
    background-color: #f8f9fa;
    border-radius: 0 4px 4px 0;
    margin-bottom: 10px;
    margin-left: 10px;
    transition: transform 0.2s;
    position: relative;
  }

  .activity-item:hover {
    transform: translateX(5px);
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  }

  .activity-dot {
    position: absolute;
    left: -8px;
    top: 15px;
    width: 14px;
    height: 14px;
    background-color: #212529;
    border-radius: 50%;
    border: 2px solid #fff;
  }

  .quest-panel {
    background-color: white;
    border: 1px solid #212529;
    border-radius: 8px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease;
    padding: 15px;
  }

  .quest-panel:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
  }

  .event-card {
    background-color: #f8f9fa;
    border: 1px solid #212529;
    border-radius: 8px;
    padding: 10px;
    margin-bottom: 15px;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .event-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .event-card-btn {
    color: #212529;
    text-decoration: none;
  }

  .progress {
    height: 10px;
    border-radius: 5px;
    margin-top: 5px;
  }

  .progress-bar {
    background-color: #212529;
  }

  .badge.bg-dark {
    background-color: #212529 !important;
  }

  .btn-dark {
    background-color: #212529;
    border-color: #212529;
  }

  .btn-dark:hover {
    background-color: #000;
    border-color: #000;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .hero-section {
    text-align: center;
    padding: 20px 0;
  }

  .hero-section h2 {
    font-family: 'Pixelify Sans', serif;
    font-weight: bold;
  }

  .nav-link {
    font-weight: 600;
    transition: transform 0.2s;
  }

  .nav-link:hover {
    transform: translateY(-2px);
  }

  .nav-link.active {
    border-bottom: 2px solid #212529;
  }

  .box {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100%;
    width: 198px;
  }
</style>