const initialState = {
  workspace: { reviewedHours: 0, billableHours: 0, confidence: 0, unresolvedGaps: 0 },
  policy: {
    captureIntervalMinutes: 0,
    localOnlyScreenshots: false,
    retentionDays: 0,
    excludedApps: [],
    excludedDomains: []
  },
  intervals: [],
  screenshots: [],
  idlePrompts: [],
  reports: []
};

function loadData() {
  return initialState;
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
  if (intervals.length === 0) {
    lanes.innerHTML = `<div class="empty-state">No captured intervals yet. Start capture from the desktop agent, then review the day here.</div>`;
    return;
  }
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
  if (screenshots.length === 0) {
    strip.innerHTML = `<div class="empty-state">No screenshot evidence has been captured.</div>`;
    return;
  }
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
  if (prompts.length === 0) {
    list.innerHTML = `<div class="empty-state">No idle or resumption prompts need review.</div>`;
    return;
  }
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
  if (reports.length === 0) {
    rows.innerHTML = `<tr><td colspan="4" class="empty-table">No reportable time yet.</td></tr>`;
    return;
  }
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
    ["Retention", policy.retentionDays > 0 ? `${policy.retentionDays} days` : "Not configured"],
    ["Excluded apps", policy.excludedApps.length > 0 ? policy.excludedApps.join(", ") : "None"],
    ["Excluded domains", policy.excludedDomains.length > 0 ? policy.excludedDomains.join(", ") : "None"]
  ];
  list.innerHTML = rows.map(([label, value]) => `<dt>${label}</dt><dd>${value}</dd>`).join("");
}

function bindCaptureToggle() {
  const button = document.getElementById("capture-toggle");
  let active = false;
  button.addEventListener("click", () => {
    active = !active;
    button.textContent = active ? "Stop capture" : "Start capture";
  });
}

const data = loadData();
renderMetrics(data);
renderTimeline(data.intervals);
renderScreenshots(data.screenshots);
renderPrompts(data.idlePrompts);
renderReports(data.reports);
renderPolicy(data.policy);
bindCaptureToggle();
