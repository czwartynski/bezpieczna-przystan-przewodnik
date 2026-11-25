(() => {
  const recordings = new Map();
  const player = new Audio();
  let capture;
  let starting = false;
  let playing = null;
  let data = null;
  let neutral = false;
  let calculatorShortcuts = null;
  try {
    neutral = sessionStorage.getItem('calculator-view') === 'true';
    calculatorShortcuts = JSON.parse(sessionStorage.getItem('calculator-shortcuts'));
  } catch (_) {
    // The calculator still works when the browser disables session storage.
  }
  document.title = neutral ? 'Kalkulator' : 'Bezpieczna Przystań';

  const release = (stream) => stream.getTracks().forEach(track => track.stop());
  function pause() {
    player.pause();
    player.removeAttribute('src');
    player.load();
    playing = null;
  }
  player.addEventListener('ended', pause);

  const actions = {
    async start() {
      if (capture || starting) throw Error('Nagrywanie już trwa.');
      if (!globalThis.isSecureContext || !navigator.mediaDevices?.getUserMedia ||
          typeof MediaRecorder === 'undefined') {
        throw Error('Nagrywanie wymaga HTTPS lub localhost i obsługiwanej przeglądarki.');
      }
      starting = true;
      let stream;
      try {
        pause();
        stream = await navigator.mediaDevices.getUserMedia({audio: true});
        const recorder = new MediaRecorder(stream);
        const created = Date.now();
        const chunks = [];
        let failure;
        const finished = new Promise(resolve => {
          recorder.addEventListener('dataavailable', event => {
            if (event.data.size) chunks.push(event.data);
          });
          recorder.addEventListener('error', () => {
            failure = 'Przeglądarka przerwała nagrywanie.';
            release(stream);
          });
          recorder.addEventListener('stop', () => {
            release(stream);
            capture = null;
            const blob = new Blob(chunks, {type: recorder.mimeType || chunks[0]?.type});
            if (failure || !blob.size) {
              resolve(failure || 'Nagranie jest puste.');
              return;
            }
            const id = crypto.randomUUID();
            recordings.set(id, {id, created, duration: Date.now() - created,
              url: URL.createObjectURL(blob)});
            resolve(null);
          }, {once: true});
        });
        recorder.start();
        capture = {recorder, created, finished};
      } catch (error) {
        if (stream) release(stream);
        if (error.name === 'NotAllowedError') throw Error('Brak zgody na dostęp do mikrofonu.');
        throw Error('Nie udało się uruchomić mikrofonu.');
      } finally {
        starting = false;
      }
    },
    async stop() {
      const current = capture;
      if (!current) return;
      if (current.recorder.state !== 'inactive') current.recorder.stop();
      const failure = await current.finished;
      if (failure) throw Error(failure);
    },
    async play(id) {
      const item = recordings.get(id);
      if (!item) throw Error('Nagranie jest niedostępne.');
      pause();
      player.src = item.url;
      playing = id;
      try {
        await player.play();
      } catch (error) {
        pause();
        throw Error('Nie udało się odtworzyć nagrania.');
      }
    },
    pause,
    delete(id) {
      if (playing === id) pause();
      const item = recordings.get(id);
      if (item) URL.revokeObjectURL(item.url);
      recordings.delete(id);
    },
    status() {
      return JSON.stringify({
        recordings: [...recordings.values()].reverse().map(({id, created, duration}) =>
          ({id, created, duration})),
        started: capture?.created ?? null,
        playing,
      });
    },
    loadNeutral: () => String(neutral),
    saveNeutral(value) {
      neutral = value === 'true';
      document.title = neutral ? 'Kalkulator' : 'Bezpieczna Przystań';
      try {
        if (neutral) sessionStorage.setItem('calculator-view', 'true');
        else sessionStorage.removeItem('calculator-view');
      } catch (_) {
        // Keep the current view in memory when storage is unavailable.
      }
    },
    load: () => data ?? (calculatorShortcuts
      ? JSON.stringify({entries: [], plan: '', calculatorShortcuts}) : null),
    save(value) {
      data = value;
      calculatorShortcuts = JSON.parse(value).calculatorShortcuts ?? null;
      try {
        if (calculatorShortcuts) {
          sessionStorage.setItem('calculator-shortcuts', JSON.stringify(calculatorShortcuts));
        }
      } catch (_) {
        // Keep the shortcuts in memory when storage is unavailable.
      }
    },
  };

  globalThis.przystanAudio = async (method, argument) => {
    return (await actions[method](argument)) ?? null;
  };
})();
