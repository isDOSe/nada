document.addEventListener('DOMContentLoaded', init);
// hola
function init() {
    var views = {
        home: document.getElementById('home-view'),
        setup: document.getElementById('setup-view'),
        timer: document.getElementById('timer-view'),
        complete: document.getElementById('complete-view'),
        paused: document.getElementById('paused-view'),
        about: document.getElementById('about-view'),
        philosophy: document.getElementById('philosophy-view')
    };

    var btnStartTimer = document.getElementById('btn-start-timer');
    var btnAbout = document.getElementById('btn-about');
    var minutesInput = document.getElementById('minutes-input');
    var inputError = document.getElementById('input-error');
    var btnStart = document.getElementById('btn-start');
    var btnBackSetup = document.getElementById('btn-back-setup');
    var timerDisplay = document.getElementById('timer-display');
    var progressFill = document.getElementById('progress-fill');
    var statusMsg = document.getElementById('status-msg');
    var btnPause = document.getElementById('btn-pause');
    var btnEnd = document.getElementById('btn-end');
    var completeMsg = document.getElementById('complete-msg');
    var btnBackComplete = document.getElementById('btn-back-complete');
    var btnAboutBack = document.getElementById('btn-about-back');
    var btnPhilosophyBack = document.getElementById('btn-philosophy-back');
    var btnPhilosophyAbout = document.getElementById('btn-philosophy-about');
    var pausedTime = document.getElementById('paused-time');
    var btnResume = document.getElementById('btn-resume');
    var btnEndPaused = document.getElementById('btn-end-paused');
    var presets = document.querySelectorAll('.preset');

    var timeRemaining = 0;
    var initialDuration = 0;
    var timerInterval = null;
    var isRunning = false;
    var isPausedState = false;

    function showScreen(screenName) {
        var key;
        for (key in views) {
            if (views.hasOwnProperty(key)) {
                views[key].classList.add('hidden');
            }
        }
        if (views[screenName]) {
            views[screenName].classList.remove('hidden');
        }
    }

    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60);
        var secs = seconds % 60;
        var m = mins < 10 ? '0' + mins : '' + mins;
        var s = secs < 10 ? '0' + secs : '' + secs;
        return m + ':' + s;
    }

    function checkInput() {
        var value = minutesInput.value;
        var num = parseInt(value, 10);
        
        if (value === '' || isNaN(num) || num < 1) {
            inputError.classList.add('visible');
            btnStart.disabled = true;
            return false;
        }
        
        inputError.classList.remove('visible');
        btnStart.disabled = false;
        return true;
    }

    function launchTimer(minutes) {
        initialDuration = minutes * 60;
        timeRemaining = initialDuration;
        isRunning = true;
        isPausedState = false;
        
        timerDisplay.textContent = formatTime(timeRemaining);
        btnPause.textContent = 'Pausar';
        refreshProgress();
        showScreen('timer');
        
        timerInterval = setInterval(tick, 1000);
    }

    function tick() {
        timeRemaining--;
        timerDisplay.textContent = formatTime(timeRemaining);
        refreshProgress();
        
        if (timeRemaining <= 60) {
            statusMsg.textContent = 'Ya casi... o tal vez no.';
        } else if (timeRemaining <= 300) {
            statusMsg.textContent = 'El vacío se aproxima.';
        } else {
            statusMsg.textContent = 'Enfocado. O no haciendo nada. Lo mismo.';
        }
        
        if (timeRemaining <= 0) {
            clearInterval(timerInterval);
            isRunning = false;
            var mins = Math.floor(initialDuration / 60);
            completeMsg.innerHTML = 'Has no hecho nada por ' + mins + ' minutos.<br>Increíblemente productivo.';
            showScreen('complete');
        }
    }

    function refreshProgress() {
        if (initialDuration > 0) {
            var progress = ((initialDuration - timeRemaining) / initialDuration) * 100;
            progressFill.style.width = progress + '%';
        }
    }

    function togglePause() {
        if (!isRunning) return;
        
        if (isPausedState) {
            isPausedState = false;
            btnPause.textContent = 'Pausar';
            pausedTime.textContent = formatTime(timeRemaining);
            showScreen('timer');
            timerInterval = setInterval(tick, 1000);
        } else {
            isPausedState = true;
            clearInterval(timerInterval);
            btnPause.textContent = 'Continuar';
            pausedTime.textContent = formatTime(timeRemaining);
            showScreen('paused');
        }
    }

    function exitTimer() {
        if (timerInterval) {
            clearInterval(timerInterval);
            timerInterval = null;
        }
        isRunning = false;
        isPausedState = false;
        showScreen('home');
    }

    function returnHome() {
        exitTimer();
    }

    btnStartTimer.onclick = function() {
        checkInput();
        showScreen('setup');
    };

    btnAbout.onclick = function() {
        showScreen('about');
    };

    minutesInput.oninput = checkInput;

    var i;
    for (i = 0; i < presets.length; i++) {
        presets[i].onclick = function() {
            minutesInput.value = this.getAttribute('data-minutes');
            checkInput();
        };
    }

    btnStart.onclick = function() {
        if (checkInput()) {
            var minutes = parseInt(minutesInput.value, 10);
            launchTimer(minutes);
        }
    };

    btnBackSetup.onclick = returnHome;
    btnBackComplete.onclick = returnHome;
    btnAboutBack.onclick = returnHome;
    btnPhilosophyBack.onclick = returnHome;
btnPhilosophyAbout.onclick = function() {
        showScreen('about');
    };

    var philosophyLink = document.querySelector('.philosophy-link');
    if (philosophyLink) {
        philosophyLink.onclick = function() {
            showScreen('philosophy');
        };
    }

    btnPause.onclick = togglePause;
    btnEnd.onclick = exitTimer;
    btnResume.onclick = togglePause;
    btnEndPaused.onclick = exitTimer;

    showScreen('home');
}