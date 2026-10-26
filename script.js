(() => {
  'use strict';

  const STORAGE_KEY = 'nada.web.v1';
  const MIN_SESSION_MS = 3000;

  const MONTHS = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  const WEEKDAYS = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  const DEFAULT_SETTINGS = {
    quickMinutes: [15, 25, 45],
    mode: 'free',
    goalMinutes: 25,
    soundEnabled: true,
  };

  const el = { views: {} };
  let data;
  let lastFinished = null;
  let ticker = null;
  let audioContext = null;
  let copiedTimer = null;
  let pendingDeleteId = null;
  let currentClock = '';

  function two(value) {
    return String(value).padStart(2, '0');
  }

  function dayKey(date) {
    return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;
  }

  function clockTime(timestamp) {
    const date = new Date(timestamp);
    return `${two(date.getHours())}:${two(date.getMinutes())}`;
  }

  function journalDate(date) {
    return `${WEEKDAYS[(date.getDay() + 6) % 7]} ${date.getDate()} de ${MONTHS[date.getMonth()]}`;
  }

  function longDate(timestamp) {
    const date = new Date(timestamp);
    return `${date.getDate()} de ${MONTHS[date.getMonth()]} de ${date.getFullYear()}`;
  }

  function relativeDay(timestamp) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const date = new Date(timestamp);
    const target = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const difference = Math.round((today - target) / 86400000);

    if (difference === 0) return 'hoy';
    if (difference === 1) return 'ayer';
    if (difference < 7 && difference > 0) {
      return WEEKDAYS[(target.getDay() + 6) % 7];
    }
    return `${WEEKDAYS[(target.getDay() + 6) % 7]} ${target.getDate()} de ${MONTHS[target.getMonth()]}`;
  }

  function stopwatch(milliseconds) {
    const total = Math.max(0, Math.floor(milliseconds / 1000));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const seconds = total % 60;
    if (hours > 0) return `${hours}:${two(minutes)}:${two(seconds)}`;
    return `${two(minutes)}:${two(seconds)}`;
  }

  function compactDuration(milliseconds, zeroAsDash = false) {
    const total = Math.max(0, Math.floor(milliseconds / 1000));
    if (total < 1) return zeroAsDash ? '—' : '0 min';
    if (total < 60) return `${total} s`;

    const minutes = Math.floor(total / 60);
    if (minutes < 60) return `${minutes} min`;

    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    return rest === 0 ? `${hours} h` : `${hours} h ${rest} min`;
  }

  function spokenDuration(milliseconds) {
    const total = Math.max(0, Math.floor(milliseconds / 1000));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const seconds = total % 60;

    const unit = (value, singular, plural) =>
      `${value} ${value === 1 ? singular : plural}`;

    if (hours > 0) {
      const tail = minutes > 0 ? ` y ${unit(minutes, 'minuto', 'minutos')}` : '';
      return `${unit(hours, 'hora', 'horas')}${tail}`;
    }
    if (minutes > 0) {
      const tail = seconds > 0 ? ` y ${unit(seconds, 'segundo', 'segundos')}` : '';
      return `${unit(minutes, 'minuto', 'minutos')}${tail}`;
    }
    return unit(seconds, 'segundo', 'segundos');
  }

  function streakLabel(days) {
    if (days <= 0) return 'sin racha';
    if (days === 1) return 'racha de 1 día';
    return `racha de ${days} días`;
  }

  function sessionCountLabel(count) {
    if (count === 0) return 'ninguna sesión';
    if (count === 1) return '1 sesión';
    return `${count} sesiones`;
  }

  function freshData() {
    return {
      version: 1,
      sessions: [],
      active: null,
      settings: {
        quickMinutes: [...DEFAULT_SETTINGS.quickMinutes],
        mode: DEFAULT_SETTINGS.mode,
        goalMinutes: DEFAULT_SETTINGS.goalMinutes,
        soundEnabled: DEFAULT_SETTINGS.soundEnabled,
      },
    };
  }

  function isMinute(value) {
    return Number.isInteger(value) && value >= 1 && value <= 999;
  }

  function normalizeSession(raw) {
    if (!raw || typeof raw !== 'object') return null;
    const startedAt = Number(raw.startedAt);
    const endedAt = Number(raw.endedAt);
    const durationMs = Number(raw.durationMs);
    if (!Number.isFinite(startedAt) || !Number.isFinite(endedAt) || !Number.isFinite(durationMs)) {
      return null;
    }
    if (durationMs <= 0) return null;

    const goalMs = raw.goalMs == null ? null : Number(raw.goalMs);
    return {
      id: typeof raw.id === 'string' && raw.id ? raw.id : newId(startedAt),
      startedAt,
      endedAt,
      durationMs,
      mode: raw.mode === 'goal' ? 'goal' : 'free',
      goalMs: Number.isFinite(goalMs) && goalMs > 0 ? goalMs : null,
      completed: raw.completed === true,
    };
  }

  function normalizeActive(raw) {
    if (!raw || typeof raw !== 'object') return null;
    const startedAt = Number(raw.startedAt);
    const lastResumedAt = Number(raw.lastResumedAt);
    const accumulatedMs = Number(raw.accumulatedMs);
    if (!Number.isFinite(startedAt) || !Number.isFinite(lastResumedAt) || !Number.isFinite(accumulatedMs)) {
      return null;
    }
    if (accumulatedMs < 0) return null;

    const goalMs = raw.goalMs == null ? null : Number(raw.goalMs);
    return {
      startedAt,
      lastResumedAt,
      accumulatedMs,
      mode: raw.mode === 'goal' ? 'goal' : 'free',
      goalMs: Number.isFinite(goalMs) && goalMs > 0 ? goalMs : null,
      running: raw.running === true,
    };
  }

  function normalizeSettings(raw) {
    const settings = freshData().settings;
    if (!raw || typeof raw !== 'object') return settings;

    if (Array.isArray(raw.quickMinutes) && raw.quickMinutes.length === 3) {
      const quick = raw.quickMinutes.map((value) => Number(value));
      if (quick.every(isMinute)) settings.quickMinutes = quick;
    }
    if (raw.mode === 'free' || raw.mode === 'goal') settings.mode = raw.mode;
    if (isMinute(Number(raw.goalMinutes))) settings.goalMinutes = Number(raw.goalMinutes);
    if (typeof raw.soundEnabled === 'boolean') settings.soundEnabled = raw.soundEnabled;
    return settings;
  }

  function loadData() {
    const next = freshData();
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return next;
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') return next;

      if (Array.isArray(parsed.sessions)) {
        next.sessions = parsed.sessions
          .map(normalizeSession)
          .filter(Boolean)
          .sort((a, b) => b.startedAt - a.startedAt);
      }
      next.settings = normalizeSettings(parsed.settings);
      next.active = normalizeActive(parsed.active);
      return next;
    } catch (_) {
      return next;
    }
  }

  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch (_) {
      // Consola privada o modo incógnito: la sesión sigue viva en memoria.
    }
  }

  function newId(startedAt) {
    return `${startedAt.toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  }

  function elapsedAt(active, now) {
    if (!active) return 0;
    if (!active.running) return active.accumulatedMs;
    const live = Math.max(0, now - active.lastResumedAt);
    return active.accumulatedMs + live;
  }

  function computeStats(sessions) {
    if (sessions.length === 0) {
      return {
        total: 0, today: 0, week: 0, sessionCount: 0,
        streakDays: 0, longest: 0, average: 0,
      };
    }

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const weekStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6).getTime();
    let total = 0;
    let today = 0;
    let week = 0;
    let longest = 0;
    const days = new Set();

    for (const session of sessions) {
      total += session.durationMs;
      if (session.durationMs > longest) longest = session.durationMs;

      const date = new Date(session.startedAt);
      const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
      if (startOfDay === todayStart) today += session.durationMs;
      if (startOfDay >= weekStart) week += session.durationMs;
      days.add(dayKey(date));
    }

    return {
      total,
      today,
      week,
      sessionCount: sessions.length,
      streakDays: computeStreak(days, todayStart),
      longest,
      average: Math.floor(total / sessions.length),
    };
  }

  function computeStreak(days, todayStart) {
    if (days.size === 0) return 0;
    let cursor = new Date(todayStart);
    if (!days.has(dayKey(cursor))) {
      cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() - 1);
    }
    let streak = 0;
    while (days.has(dayKey(cursor))) {
      streak += 1;
      cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() - 1);
    }
    return streak;
  }

  function cacheElements() {
    el.aurora = document.getElementById('aurora');
    el.views = {
      home: document.getElementById('view-home'),
      session: document.getElementById('view-session'),
      summary: document.getElementById('view-summary'),
      history: document.getElementById('view-history'),
      manifesto: document.getElementById('view-manifesto'),
    };

    el.dateline = document.getElementById('dateline');
    el.homeTotal = document.getElementById('home-total');
    el.homeMeta = document.getElementById('home-meta');
    el.homeTotalButton = document.getElementById('home-total-button');
    el.choices = document.getElementById('choices');
    el.durationHint = document.getElementById('duration-hint');
    el.startSession = document.getElementById('start-session');
    el.homeHistory = document.getElementById('home-history');
    el.openSettings = document.getElementById('open-settings');
    el.openManifesto = document.getElementById('open-manifesto');

    el.sessionView = document.getElementById('view-session');
    el.sessionStatus = document.getElementById('session-status');
    el.clock = document.getElementById('clock');
    el.sessionLine = document.getElementById('session-line');
    el.sessionSub = document.getElementById('session-sub');
    el.goalBlock = document.getElementById('goal-block');
    el.goalLabel = document.getElementById('goal-label');
    el.goalRemaining = document.getElementById('goal-remaining');
    el.progressFill = document.getElementById('progress-fill');
    el.togglePause = document.getElementById('toggle-pause');
    el.finishSession = document.getElementById('finish-session');

    el.summaryLabel = document.getElementById('summary-label');
    el.summaryDuration = document.getElementById('summary-duration');
    el.summaryCopy = document.getElementById('summary-copy');
    el.summaryTotal = document.getElementById('summary-total');
    el.closeSummary = document.getElementById('close-summary');
    el.summaryHome = document.getElementById('summary-home');
    el.startAgain = document.getElementById('start-again');

    el.historyTotal = document.getElementById('history-total');
    el.historyMeta = document.getElementById('history-meta');
    el.historySince = document.getElementById('history-since');
    el.historyLongest = document.getElementById('history-longest');
    el.historyActions = document.getElementById('history-actions');
    el.historyRule = document.getElementById('history-rule');
    el.historyEntries = document.getElementById('history-entries');
    el.historyEmpty = document.getElementById('history-empty');
    el.historyBack = document.getElementById('history-back');
    el.historyStart = document.getElementById('history-start');
    el.copySummary = document.getElementById('copy-summary');

    el.manifestoBack = document.getElementById('manifesto-back');

    el.settingsDialog = document.getElementById('settings-dialog');
    el.timeRows = document.getElementById('time-rows');
    el.soundToggle = document.getElementById('sound-toggle');
    el.testSound = document.getElementById('test-sound');
    el.openManifestoSettings = document.getElementById('open-manifesto-settings');
    el.openAbout = document.getElementById('open-about');

    el.sessionDialog = document.getElementById('session-dialog');
    el.sessionDialogLabel = document.getElementById('session-dialog-label');
    el.sessionDialogDuration = document.getElementById('session-dialog-duration');
    el.sessionDialogCopy = document.getElementById('session-dialog-copy');
    el.deleteSession = document.getElementById('delete-session');

    el.confirmDialog = document.getElementById('confirm-dialog');
    el.confirmCancel = document.getElementById('confirm-cancel');
    el.confirmDelete = document.getElementById('confirm-delete');

    el.aboutDialog = document.getElementById('about-dialog');
    el.live = document.getElementById('live');
  }

  function bindEvents() {
    el.startSession.addEventListener('click', startSession);
    el.homeTotalButton.addEventListener('click', () => showView('history'));
    el.homeHistory.addEventListener('click', () => showView('history'));
    el.openSettings.addEventListener('click', openSettings);
    el.openManifesto.addEventListener('click', () => showView('manifesto'));
    el.historyBack.addEventListener('click', () => showView('home'));
    el.manifestoBack.addEventListener('click', () => showView('home'));

    el.togglePause.addEventListener('click', togglePause);
    el.finishSession.addEventListener('click', () => finishSession());

    el.closeSummary.addEventListener('click', dismissSummary);
    el.summaryHome.addEventListener('click', dismissSummary);
    el.startAgain.addEventListener('click', startSession);

    el.historyStart.addEventListener('click', startSession);
    el.copySummary.addEventListener('click', copySummary);

    el.soundToggle.addEventListener('click', () => {
      data.settings.soundEnabled = !data.settings.soundEnabled;
      updateSoundToggle();
      save();
    });
    el.testSound.addEventListener('click', () => {
      primeAudio();
      playChime();
    });
    el.openAbout.addEventListener('click', () => {
      el.settingsDialog.close();
      el.aboutDialog.showModal();
      focusDialogClose(el.aboutDialog);
    });
    el.openManifestoSettings.addEventListener('click', () => {
      el.settingsDialog.close();
      showView('manifesto');
    });

    el.sessionDialog.addEventListener('close', () => {
      pendingDeleteId = null;
    });
    el.deleteSession.addEventListener('click', () => {
      if (!pendingDeleteId) return;
      el.confirmDialog.showModal();
      el.confirmCancel.focus();
    });

    el.confirmCancel.addEventListener('click', () => {
      el.confirmDialog.close();
    });
    el.confirmDelete.addEventListener('click', () => {
      if (!pendingDeleteId) return;
      const next = data.sessions.filter((session) => session.id !== pendingDeleteId);
      if (next.length === data.sessions.length) return;
      data.sessions = next;
      pendingDeleteId = null;
      save();
      el.confirmDialog.close();
      if (el.sessionDialog.open) el.sessionDialog.close();
      renderHistory();
      renderHome();
      announce('sesión borrada.');
    });

    for (const dialog of document.querySelectorAll('dialog')) {
      dialog.addEventListener('click', (event) => {
        if (event.target === dialog) dialog.close();
      });
    }

    for (const button of document.querySelectorAll('[data-close]')) {
      button.addEventListener('click', () => {
        const dialog = button.closest('dialog');
        if (dialog) dialog.close();
      });
    }

    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        stopTicker();
        return;
      }
      catchUp();
    });

    window.addEventListener('focus', catchUp);
  }

  function showView(name) {
    for (const [key, view] of Object.entries(el.views)) {
      view.classList.toggle('is-active', key === name);
    }

    const isSession = name === 'session';
    el.aurora.classList.toggle('is-on', isSession);
    if (!isSession) el.aurora.classList.remove('is-paused');

    const titles = {
      home: 'nada! — el contador de lo que no hiciste',
      session: 'en curso · nada!',
      summary: 'sesión guardada · nada!',
      history: 'registro · nada!',
      manifesto: 'la filosofía del vacío · nada!',
    };
    document.title = titles[name] || titles.home;

    if (name === 'home') renderHome();
    if (name === 'history') renderHistory();

    const scroller = el.views[name].querySelector(
      '.home-body, .session-body, .summary-body, .history-body, .prose'
    );
    if (scroller) scroller.scrollTop = 0;
  }

  function renderHome() {
    const stats = computeStats(data.sessions);
    el.dateline.textContent = `hoy, ${journalDate(new Date())}`;
    el.homeTotal.textContent = compactDuration(stats.total);
    el.homeMeta.textContent = stats.sessionCount === 0
      ? 'tu primera sesión empieza cuando quieras.'
      : `${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}`;
    el.homeTotalButton.setAttribute(
      'aria-label',
      `ver el registro: ${compactDuration(stats.total)} sin hacer nada, ${sessionCountLabel(stats.sessionCount)}`
    );
    el.durationHint.textContent = data.settings.mode === 'free'
      ? 'cuenta hacia arriba. tú decides cuándo parar.'
      : 'te aviso cuando llegues. después puedes seguir.';
    renderChoices();
  }

  function renderChoices() {
    const settings = data.settings;
    const goals = [...settings.quickMinutes];
    if (!goals.includes(settings.goalMinutes)) goals.push(settings.goalMinutes);

    el.choices.replaceChildren();
    el.choices.append(createChoice('sin límite', settings.mode === 'free', () => {
      settings.mode = 'free';
      save();
      renderHome();
    }));

    for (const minutes of goals) {
      el.choices.append(createChoice(
        `${minutes} min`,
        settings.mode === 'goal' && settings.goalMinutes === minutes,
        () => {
          settings.mode = 'goal';
          settings.goalMinutes = minutes;
          save();
          renderHome();
        }
      ));
    }
  }

  function createChoice(label, selected, onSelect) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = selected ? 'choice is-selected' : 'choice';
    button.textContent = label;
    button.setAttribute('aria-pressed', String(selected));
    button.addEventListener('click', onSelect);
    return button;
  }

  function startSession() {
    if (data.active) return;
    const now = Date.now();
    const mode = data.settings.mode;
    data.active = {
      startedAt: now,
      lastResumedAt: now,
      accumulatedMs: 0,
      mode,
      goalMs: mode === 'goal' ? data.settings.goalMinutes * 60000 : null,
      running: true,
    };
    lastFinished = null;
    primeAudio();
    save();
    showView('session');
    startTicker();
    renderSession();
    announce('sesión de nada en curso.');
  }

  function startTicker() {
    stopTicker();
    ticker = window.setInterval(tick, 1000);
  }

  function stopTicker() {
    if (ticker !== null) {
      window.clearInterval(ticker);
      ticker = null;
    }
  }

  function tick() {
    const active = data.active;
    if (!active || !active.running) return;
    const now = Date.now();
    if (active.goalMs != null && elapsedAt(active, now) >= active.goalMs) {
      finishSession({ reachedGoal: true, now });
      return;
    }
    renderSession();
  }

  function catchUp() {
    const active = data.active;
    if (!active) return;
    const now = Date.now();
    if (active.running) {
      if (active.goalMs != null && elapsedAt(active, now) >= active.goalMs) {
        finishSession({ reachedGoal: true, now, playSound: false });
        return;
      }
      if (currentView === 'session') {
        renderSession();
        startTicker();
      }
    } else if (currentView === 'session') {
      renderSession();
    }
  }

  function togglePause() {
    const active = data.active;
    if (!active) return;
    const now = Date.now();

    if (active.running) {
      active.accumulatedMs = elapsedAt(active, now);
      active.lastResumedAt = now;
      active.running = false;
      stopTicker();
      save();
      renderSession();
      announce('sesión en pausa.');
      return;
    }

    if (active.goalMs != null && elapsedAt(active, now) >= active.goalMs) {
      finishSession({ reachedGoal: true, now });
      return;
    }

    active.running = true;
    active.lastResumedAt = now;
    save();
    startTicker();
    renderSession();
    announce('sesión en curso.');
  }

  function finishSession({ reachedGoal = false, now = Date.now(), playSound = true } = {}) {
    const active = data.active;
    if (!active) return;

    const measured = elapsedAt(active, now);
    const target = active.goalMs;
    const completed = reachedGoal || (target != null && measured >= target);
    let duration = measured;
    let endedAt = now;

    if (completed && target != null) {
      const overshoot = measured - target;
      if (overshoot > 0) endedAt = now - overshoot;
      duration = target;
    }

    let session = null;
    if (duration >= MIN_SESSION_MS) {
      session = {
        id: newId(active.startedAt),
        startedAt: active.startedAt,
        endedAt,
        durationMs: duration,
        mode: active.mode,
        goalMs: target,
        completed,
      };
      data.sessions = [session, ...data.sessions]
        .sort((a, b) => b.startedAt - a.startedAt);
    }

    data.active = null;
    lastFinished = session;
    stopTicker();
    save();
    el.aurora.classList.remove('is-on', 'is-paused');

    if (session) {
      if (playSound && data.settings.soundEnabled) playChime();
      renderSummary(session);
      showView('summary');
      announce(completed ? 'meta cumplida. sesión guardada.' : 'sesión guardada.');
      return;
    }

    showView('home');
    announce('la sesión fue demasiado corta. no se guardó.');
  }

  function renderSession() {
    const active = data.active;
    if (!active) return;

    const now = Date.now();
    const elapsed = elapsedAt(active, now);
    const running = active.running;
    const clock = stopwatch(elapsed);

    renderClock(clock);
    el.clock.setAttribute('aria-label', spokenDuration(elapsed));
    el.sessionStatus.hidden = running;
    el.sessionLine.textContent = running
      ? (elapsed < 2000 ? 'acabas de dejar de hacer algo' : `llevas ${spokenDuration(elapsed)} sin hacer nada`)
      : 'el vacío se quedó quieto.';
    el.sessionView.classList.toggle('is-paused', !running);
    el.togglePause.textContent = running ? 'pausar' : 'continuar';
    el.togglePause.classList.toggle('is-depressed', !running);
    el.aurora.classList.toggle('is-paused', !running);

    if (active.goalMs == null) {
      el.sessionSub.hidden = false;
      el.sessionSub.textContent = `sin límite · desde las ${clockTime(active.startedAt)}`;
      el.goalBlock.hidden = true;
    } else {
      el.sessionSub.hidden = true;
      el.goalBlock.hidden = false;
      const remaining = Math.max(0, active.goalMs - elapsed);
      el.goalLabel.textContent = `meta de ${compactDuration(active.goalMs)}`;
      el.goalRemaining.textContent = `quedan ${stopwatch(remaining)}`;
      const progress = Math.max(0, Math.min(1, elapsed / active.goalMs));
      el.progressFill.style.transform = `scaleX(${progress})`;
    }

    document.title = running ? `${clock} · nada!` : 'en pausa · nada!';
  }

  function renderClock(text) {
    if (text === currentClock) return;
    currentClock = text;
    const fragment = document.createDocumentFragment();
    for (const character of text) {
      const span = document.createElement('span');
      span.className = character === ':' ? 'sep' : 'ch';
      span.textContent = character;
      fragment.append(span);
    }
    el.clock.replaceChildren(fragment);
  }

  function renderSummary(session) {
    const stats = computeStats(data.sessions);
    const completed = session.completed;
    const isFree = session.mode === 'free';

    el.summaryLabel.textContent = completed
      ? `meta cumplida · sesión ${stats.sessionCount}`
      : `sesión ${stats.sessionCount} guardada`;
    el.summaryDuration.textContent = compactDuration(session.durationMs);
    el.summaryCopy.textContent = completed
      ? 'llegaste a la meta sin producir absolutamente nada. impecable.'
      : isFree
        ? 'no estaban en tu agenda. ahora están en tu registro.'
        : 'cortaste antes de la meta. igual cuenta.';
    el.summaryTotal.textContent = `en total ${compactDuration(stats.total)} · ${sessionCountLabel(stats.sessionCount)}`;
  }

  function dismissSummary() {
    lastFinished = null;
    showView('home');
  }

  function renderHistory() {
    const sessions = data.sessions;
    const stats = computeStats(sessions);
    const hasSessions = sessions.length > 0;

    el.historyTotal.textContent = compactDuration(stats.total, true);
    el.historyMeta.textContent = `${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}`;
    el.historySince.hidden = !hasSessions;
    el.historyLongest.hidden = sessions.length < 2;
    el.historyActions.hidden = !hasSessions;
    el.historyRule.hidden = !hasSessions;
    el.historyEmpty.hidden = hasSessions;
    el.historyEntries.replaceChildren();

    if (hasSessions) {
      el.historySince.textContent = `desde el ${longDate(sessions[sessions.length - 1].startedAt)}`;
      if (sessions.length > 1) {
        el.historyLongest.textContent =
          `la más larga ${compactDuration(stats.longest)} · promedio ${compactDuration(stats.average)}`;
      }
      renderHistoryEntries(sessions);
    }

    resetCopyLabel();
  }

  function renderHistoryEntries(sessions) {
    const groups = new Map();
    for (const session of sessions) {
      const date = new Date(session.startedAt);
      const key = dayKey(date);
      if (!groups.has(key)) {
        groups.set(key, { day: date, total: 0, sessions: [] });
      }
      const group = groups.get(key);
      group.total += session.durationMs;
      group.sessions.push(session);
    }

    const fragment = document.createDocumentFragment();
    for (const group of groups.values()) {
      const head = document.createElement('div');
      head.className = 'day-head';
      const day = document.createElement('span');
      day.className = 'day';
      day.textContent = relativeDay(group.day.getTime());
      const total = document.createElement('span');
      total.className = 'day-total';
      total.textContent = compactDuration(group.total);
      head.append(day, total);

      const rule = document.createElement('div');
      rule.className = 'hairline day-rule';

      fragment.append(head, rule);
      for (const session of group.sessions) {
        fragment.append(createSessionRow(session));
      }
    }
    el.historyEntries.append(fragment);
  }

  function createSessionRow(session) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'session-row';
    button.setAttribute(
      'aria-label',
      `${compactDuration(session.durationMs)} de nada, ${relativeDay(session.startedAt)} a las ${clockTime(session.startedAt)}`
    );

    const duration = document.createElement('span');
    duration.className = 'session-duration';
    duration.textContent = compactDuration(session.durationMs);

    const meta = document.createElement('span');
    meta.className = 'session-meta';
    const range = document.createElement('span');
    range.className = 'session-range';
    range.textContent = `${clockTime(session.startedAt)} — ${clockTime(session.endedAt)}`;
    const mode = document.createElement('span');
    mode.className = 'session-mode';
    mode.textContent = sessionModeLabel(session);
    meta.append(range, mode);

    button.append(duration, meta);
    button.addEventListener('click', () => openSessionDetail(session));
    return button;
  }

  function sessionModeLabel(session) {
    if (session.mode === 'free') return 'sin límite';
    if (session.completed) return 'meta cumplida';
    return `meta ${compactDuration(session.goalMs || 0)}`;
  }

  function openSessionDetail(session) {
    pendingDeleteId = session.id;
    el.sessionDialogLabel.textContent =
      `${relativeDay(session.startedAt)} · ${clockTime(session.startedAt)} — ${clockTime(session.endedAt)}`;
    el.sessionDialogDuration.textContent = compactDuration(session.durationMs);
    el.sessionDialogCopy.textContent = session.goalMs == null
      ? 'sin límite. contó hacia arriba hasta que decidiste parar.'
      : session.completed
        ? `meta de ${compactDuration(session.goalMs)}. la cumpliste sin hacer nada.`
        : `meta de ${compactDuration(session.goalMs)}. la cortaste antes.`;
    el.sessionDialog.showModal();
    focusDialogClose(el.sessionDialog);
  }

  function focusDialogClose(dialog) {
    const close = dialog.querySelector('[data-close]');
    if (close) close.focus();
  }

  function openSettings() {
    renderTimeRows();
    updateSoundToggle();
    el.settingsDialog.showModal();
    el.settingsDialog.addEventListener('close', renderHome, { once: true });
  }

  function renderTimeRows() {
    el.timeRows.replaceChildren();
    data.settings.quickMinutes.forEach((minutes, index) => {
      const row = document.createElement('div');
      row.className = 'time-row';

      const input = document.createElement('input');
      input.type = 'number';
      input.min = '1';
      input.max = '999';
      input.step = '1';
      input.inputMode = 'numeric';
      input.value = String(minutes);
      input.setAttribute('aria-label', `Tiempo rápido ${index + 1} en minutos`);

      input.addEventListener('input', () => {
        const value = Number.parseInt(input.value, 10);
        if (!isMinute(value)) return;
        updateQuickMinute(index, value);
      });

      input.addEventListener('blur', () => {
        const value = Number.parseInt(input.value, 10);
        if (!isMinute(value)) {
          input.value = String(data.settings.quickMinutes[index]);
          return;
        }
        input.value = String(value);
        updateQuickMinute(index, value);
      });

      input.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') {
          event.preventDefault();
          input.blur();
        }
      });

      const unit = document.createElement('span');
      unit.className = 'unit';
      unit.textContent = 'min';

      const spacer = document.createElement('span');
      spacer.className = 'spacer';

      const minus = document.createElement('button');
      minus.type = 'button';
      minus.className = 'step';
      minus.textContent = '−';
      minus.setAttribute('aria-label', 'Restar cinco minutos');
      minus.addEventListener('click', () => stepTime(index, -5));

      const plus = document.createElement('button');
      plus.type = 'button';
      plus.className = 'step';
      plus.textContent = '+';
      plus.setAttribute('aria-label', 'Sumar cinco minutos');
      plus.addEventListener('click', () => stepTime(index, 5));

      row.append(input, unit, spacer, minus, plus);
      el.timeRows.append(row);
    });
  }

  function updateQuickMinute(index, minutes) {
    const settings = data.settings;
    if (index < 0 || index >= settings.quickMinutes.length) return;
    if (!isMinute(minutes)) return;
    const previous = settings.quickMinutes[index];
    if (previous === minutes) return;

    settings.quickMinutes[index] = minutes;
    if (settings.mode === 'goal' && settings.goalMinutes === previous) {
      settings.goalMinutes = minutes;
    }
    save();
    renderHome();
  }

  function stepTime(index, delta) {
    const inputs = el.timeRows.querySelectorAll('input');
    const input = inputs[index];
    const parsed = input ? Number.parseInt(input.value, 10) : Number.NaN;
    const base = isMinute(parsed) ? parsed : data.settings.quickMinutes[index];
    const next = Math.min(999, Math.max(1, base + delta));
    if (input) input.value = String(next);
    updateQuickMinute(index, next);
  }

  function updateSoundToggle() {
    el.soundToggle.setAttribute('aria-checked', String(data.settings.soundEnabled));
  }

  async function copySummary() {
    const stats = computeStats(data.sessions);
    if (stats.sessionCount === 0) return;

    const text = `nada!\n${compactDuration(stats.total)} sin hacer nada\n`
      + `${sessionCountLabel(stats.sessionCount)} · ${streakLabel(stats.streakDays)}`;

    let copied = false;
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(text);
        copied = true;
      }
    } catch (_) {
      copied = false;
    }

    if (!copied) copied = fallbackCopy(text);
    if (!copied) return;

    el.copySummary.textContent = 'copiado';
    el.copySummary.classList.add('is-emphasized');
    window.clearTimeout(copiedTimer);
    copiedTimer = window.setTimeout(resetCopyLabel, 2000);
    announce('resumen copiado.');
  }

  function fallbackCopy(text) {
    const area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.append(area);
    area.select();
    let copied = false;
    try {
      copied = document.execCommand('copy');
    } catch (_) {
      copied = false;
    }
    area.remove();
    return copied;
  }

  function resetCopyLabel() {
    el.copySummary.textContent = 'copiar resumen';
    el.copySummary.classList.remove('is-emphasized');
  }

  function primeAudio() {
    if (audioContext) {
      if (audioContext.state === 'suspended') {
        audioContext.resume().catch(() => {});
      }
      return;
    }
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return;
    try {
      audioContext = new Ctx();
    } catch (_) {
      audioContext = null;
    }
  }

  function playChime() {
    primeAudio();
    const context = audioContext;
    if (!context) return;
    if (context.state === 'suspended') context.resume().catch(() => {});

    try {
      const start = context.currentTime + 0.02;
      const notes = [
        { frequency: 523.25, at: 0, length: 0.75 },
        { frequency: 783.99, at: 0.18, length: 0.75 },
      ];

      for (const note of notes) {
        const oscillator = context.createOscillator();
        const gain = context.createGain();
        oscillator.type = 'sine';
        oscillator.frequency.value = note.frequency;
        gain.gain.setValueAtTime(0.0001, start + note.at);
        gain.gain.exponentialRampToValueAtTime(0.18, start + note.at + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, start + note.at + note.length);
        oscillator.connect(gain);
        gain.connect(context.destination);
        oscillator.start(start + note.at);
        oscillator.stop(start + note.at + note.length + 0.02);
      }
    } catch (_) {
      // El sonido es un detalle; nunca debe romper el cierre de una sesión.
    }
  }

  function announce(message) {
    el.live.textContent = '';
    window.setTimeout(() => {
      el.live.textContent = message;
    }, 30);
  }

  function init() {
    cacheElements();
    data = loadData();
    bindEvents();
    renderHome();

    const active = data.active;
    if (!active) {
      showView('home');
      return;
    }

    if (active.running && active.goalMs != null && elapsedAt(active, Date.now()) >= active.goalMs) {
      finishSession({ reachedGoal: true, now: Date.now(), playSound: false });
      return;
    }

    showView('session');
    startTicker();
    renderSession();
  }

  document.addEventListener('DOMContentLoaded', init);
})();
