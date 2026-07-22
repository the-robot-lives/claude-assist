const fallbackData = {
  workspace: { reviewedHours: 6.4, billableHours: 5.75, confidence: 87, unresolvedGaps: 3 },
  policy: {
    captureIntervalMinutes: 5,
    localOnlyScreenshots: true,
    retentionDays: 21,
    excludedApps: ["1Password", "Messages"],
    excludedDomains: ["bank.example", "health.example"]
  },
  intervals: [
    { start: "08:45", end: "10:05", project: "Timely Alpha", task: "Timeline keyboard prototype", state: "captured", confidence: 92, lane: 0, width: 18 },
    { start: "10:05", end: "10:42", project: "Incident Review", task: "Deploy monitor and client update", state: "overlap", confidence: 81, lane: 1, width: 12 },
    { start: "10:31", end: "11:18", project: "Dashboard Polish", task: "Visual QA pass", state: "inferred", confidence: 74, lane: 2, width: 14 },
    { start: "11:18", end: "11:52", project: "Idle", task: "Away from keyboard", state: "idle", confidence: 66, lane: 0, width: 10 },
    { start: "12:20", end: "14:05", project: "Incident Review", task: "Root cause notes", state: "manual", confidence: 88, lane: 0, width: 24 },
    { start: "14:05", end: "15:12", project: "Dashboard Polish", task: "Client export review", state: "private", confidence: 79, lane: 1, width: 18 }
  ],
  screenshots: [
    { time: "08:50", label: "Timeline canvas", visibility: "shareable" },
    { time: "10:15", label: "Deploy logs", visibility: "shareable" },
    { time: "10:35", label: "Design review", visibility: "redacted" },
    { time: "14:12", label: "Invoice draft", visibility: "private" }
  ],
  idlePrompts: [
    { from: "11:18", to: "11:52", suggestion: "Discard idle time", reason: "No input, screen locked" },
    { from: "15:12", to: "15:31", suggestion: "Resume Dashboard Polish", reason: "Returned to same app and document" }
  ],
  reports: [
    { client: "Aster Systems", hours: 3.05, confidence: 84, evidence: "selected screenshots" },
    { client: "HelioWorks", hours: 2.7, confidence: 77, evidence: "metadata only" }
  ]
};

async function loadData() {
  try {
    const response = await fetch("../../shared/timely-fixtures.json");
    if (!response.ok) throw new Error(`Fixture load failed: ${response.status}`);
    return await response.json();
  } catch {
    return fallbackData;
  }
}

function setText(id, value) {
  document.getElementById(id).textContent = value;
}

function renderMetrics(data) {
  setText("reviewed-hours", data.workspace.reviewedHours.toFixed(1));
  setText("billable-hours", data.workspace.billableHours.toFixed(2));
  setText("confidence", `${data.workspace.confidence}%`);
  setText("unresolved-gaps", data.workspace.unresolvedGaps);
}

function renderTimeline(intervals) {
  const lanes = document.getElementById("timeline-lanes");
  lanes.innerHTML = "";
  for (let laneIndex = 0; laneIndex < 3; laneIndex += 1) {
    const lane = document.createElement("div");
    lane.className = "lane";
    intervals
      .filter((interval) => interval.lane === laneIndex)
      .forEach((interval, index) => {
        const item = document.createElement("button");
        item.type = "button";
        item.className = `interval state-${interval.state}`;
        item.style.left = `${Math.min(78, index * 27 + laneIndex * 5)}%`;
        item.style.width = `${interval.width}%`;
        item.innerHTML = `<span>${interval.task}<small>${interval.start}-${interval.end} / ${interval.confidence}%</small></span>`;
        item.setAttribute("aria-label", `${interval.task}, ${interval.start} to ${interval.end}, ${interval.state}`);
        lane.appendChild(item);
      });
    lanes.appendChild(lane);
  }
}

function renderScreenshots(screenshots) {
  const strip = document.getElementById("screenshot-strip");
  strip.innerHTML = screenshots
    .map((shot) => `
      <div class="shot">
        <div class="shot-preview" aria-hidden="true"></div>
        <strong>${shot.time} - ${shot.label}</strong>
        <span class="badge">${shot.visibility}</span>
      </div>
    `)
    .join("");
}

function renderPrompts(prompts) {
  const list = document.getElementById("idle-prompts");
  list.innerHTML = prompts
    .map((prompt) => `
      <div class="prompt">
        <strong>${prompt.from}-${prompt.to}</strong>
        <span>${prompt.suggestion}</span>
        <small>${prompt.reason}</small>
      </div>
    `)
    .join("");
}

function renderReports(reports) {
  const rows = document.getElementById("report-rows");
  rows.innerHTML = reports
    .map((report) => `
      <tr>
        <td>${report.client}</td>
        <td>${report.hours.toFixed(2)}</td>
        <td>${report.confidence}%</td>
        <td>${report.evidence}</td>
      </tr>
    `)
    .join("");
}

function renderPolicy(policy) {
  const list = document.getElementById("policy-list");
  const rows = [
    ["Screenshot interval", `${policy.captureIntervalMinutes} minutes`],
    ["Local-only screenshots", policy.localOnlyScreenshots ? "Enabled" : "Disabled"],
    ["Retention", `${policy.retentionDays} days`],
    ["Excluded apps", policy.excludedApps.join(", ")],
    ["Excluded domains", policy.excludedDomains.join(", ")]
  ];
  list.innerHTML = rows.map(([label, value]) => `<dt>${label}</dt><dd>${value}</dd>`).join("");
}

function bindCaptureToggle() {
  const button = document.getElementById("capture-toggle");
  let paused = false;
  button.addEventListener("click", () => {
    paused = !paused;
    button.textContent = paused ? "Resume capture" : "Pause capture";
    button.classList.toggle("secondary", paused);
    button.classList.toggle("primary", !paused);
  });
}

const data = await loadData();
renderMetrics(data);
renderTimeline(data.intervals);
renderScreenshots(data.screenshots);
renderPrompts(data.idlePrompts);
renderReports(data.reports);
renderPolicy(data.policy);
bindCaptureToggle();

