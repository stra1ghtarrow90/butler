const SIGNATURE_INTERVAL_MS = 1_000;
const INITIAL_SIGNATURE_COUNT = 27_348;
const STORAGE_KEYS = {
  startTime: "keepbutler.signatureStartTime.v2",
  baseCount: "keepbutler.signatureBaseCount.v2",
};

const countNode = document.getElementById("signature-count");
const petitionForm = document.getElementById("petition-form");
const petitionThanks = document.getElementById("petition-thanks");
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

function updateCounter() {
  const now = Date.now();
  const count = getCurrentCount(now);

  countNode.textContent = formatter.format(count);

  if (previousCount !== null && count > previousCount) {
    countNode.classList.remove("bump");
    void countNode.offsetWidth;
    countNode.classList.add("bump");
  }

  previousCount = count;
}

updateCounter();
window.setInterval(updateCounter, 1000);

if (petitionForm && petitionThanks) {
  petitionForm.addEventListener("submit", (event) => {
    event.preventDefault();
    petitionForm.hidden = true;
    petitionThanks.hidden = false;
  });
}
