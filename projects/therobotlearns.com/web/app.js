const activities = [
  ["Imported", "learning-systems article bundle"],
  ["Queued", "SM-2 review cards for computing"],
  ["Planned", "weekly recall repair milestone"],
  ["Measured", "quiz weak area: spaced repetition"]
];

const learningRows = [
  ["Spaced repetition", "Recall drift", "Review due cards"],
  ["Learning systems", "Strong", "Generate applied project"],
  ["Agent memory", "Mixed", "Run headless quiz eval"],
  ["Knowledge graphs", "Needs links", "Expand related topics"]
];

const activityList = document.querySelector("#activity-list");
const learningTable = document.querySelector("#learning-table");
const syncForm = document.querySelector("#sync-form");
const bundleInput = document.querySelector("#bundle-input");
const queueCount = document.querySelector("#queue-count");

function renderActivities(extra = []) {
  activityList.innerHTML = "";
  [...extra, ...activities].slice(0, 6).forEach(([verb, detail]) => {
    const row = document.createElement("div");
    row.className = "activity";
    row.innerHTML = `<strong>${verb}</strong><span>${detail}</span>`;
    activityList.appendChild(row);
  });
}

function renderLearningRows() {
  learningRows.forEach(([topic, signal, action]) => {
    const row = document.createElement("tr");
    row.innerHTML = `<td>${topic}</td><td>${signal}</td><td>${action}</td>`;
    learningTable.appendChild(row);
  });
}

function loadQueue() {
  try {
    return JSON.parse(localStorage.getItem("trl-sync-queue") || "[]");
  } catch {
    return [];
  }
}

function saveQueue(queue) {
  localStorage.setItem("trl-sync-queue", JSON.stringify(queue));
  queueCount.textContent = `${queue.length} pending`;
  renderActivities(queue.map((item) => ["Queued", item.label]));
}

syncForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const content = bundleInput.value.trim();
  if (!content) return;
  const firstLine = content.split("\n").find(Boolean) || "content bundle";
  const queue = loadQueue();
  queue.unshift({
    label: firstLine.slice(0, 72),
    content,
    createdAt: new Date().toISOString()
  });
  saveQueue(queue);
  bundleInput.value = "";
});

renderActivities(loadQueue().map((item) => ["Queued", item.label]));
renderLearningRows();
saveQueue(loadQueue());
