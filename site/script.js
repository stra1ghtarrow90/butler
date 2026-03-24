const SIGNATURE_INTERVAL_MS = 45_000;
const INITIAL_SIGNATURE_COUNT = 27_348;
const STORAGE_KEYS = {
  startTime: "keepbutler.signatureStartTime",
  baseCount: "keepbutler.signatureBaseCount",
};

const countNode = document.getElementById("signature-count");
const timerNode = document.getElementById("signature-timer");
const meterNode = document.getElementById("signature-meter-fill");
const formatter = new Intl.NumberFormat("en-GB");

let previousCount = null;

function getCounterState() {
  try {
    const savedStart = Number(localStorage.getItem(STORAGE_KEYS.startTime));
    const savedBase = Number(localStorage.getItem(STORAGE_KEYS.baseCount));

    if (Number.isFinite(savedStart) && Number.isFinite(savedBase) && savedBase >= INITIAL_SIGNATURE_COUNT) {
      return { startTime: savedStart, baseCount: savedBase };
    }
  } catch (error) {
    // Local storage can fail in private or locked-down browsing modes.
  }

  const state = {
    startTime: Date.now(),
    baseCount: INITIAL_SIGNATURE_COUNT,
  };

  try {
    localStorage.setItem(STORAGE_KEYS.startTime, String(state.startTime));
    localStorage.setItem(STORAGE_KEYS.baseCount, String(state.baseCount));
  } catch (error) {
    // Falling back to in-memory state is fine for this counter.
  }

  return state;
}

const counterState = getCounterState();

function getElapsed(now) {
  return Math.max(0, now - counterState.startTime);
}

function getCurrentCount(now) {
  return counterState.baseCount + Math.floor(getElapsed(now) / SIGNATURE_INTERVAL_MS);
}

function getMillisecondsToNext(now) {
  const elapsed = getElapsed(now);
  const remainder = elapsed % SIGNATURE_INTERVAL_MS;
  return remainder === 0 ? SIGNATURE_INTERVAL_MS : SIGNATURE_INTERVAL_MS - remainder;
}

function formatCountdown(ms) {
  const seconds = Math.ceil(ms / 1000);
  return `${seconds}s`;
}

function updateCounter() {
  const now = Date.now();
  const count = getCurrentCount(now);
  const msToNext = getMillisecondsToNext(now);
  const progress = ((SIGNATURE_INTERVAL_MS - msToNext) / SIGNATURE_INTERVAL_MS) * 100;

  countNode.textContent = formatter.format(count);
  timerNode.textContent = `Next name lands in ${formatCountdown(msToNext)}`;
  meterNode.style.width = `${Math.max(0, Math.min(100, progress))}%`;

  if (previousCount !== null && count > previousCount) {
    countNode.classList.remove("bump");
    void countNode.offsetWidth;
    countNode.classList.add("bump");
  }

  previousCount = count;
}

updateCounter();
window.setInterval(updateCounter, 1000);
