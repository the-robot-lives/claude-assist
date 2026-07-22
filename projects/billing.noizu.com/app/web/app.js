const invoices = [];

const integrationReadiness = [
  { label: "Phoenix API", state: "Contract drafted", tone: "info" },
  { label: "PostgreSQL ledger", state: "Schema pending", tone: "warning" },
  { label: "Stripe webhooks", state: "Not connected", tone: "danger" },
  { label: "PDF worker", state: "Not connected", tone: "danger" }
];

const list = document.querySelector("#invoice-list");
const detail = document.querySelector("#invoice-detail");
const filter = document.querySelector("#status-filter");
const dialog = document.querySelector("#invoice-dialog");

let selectedId = null;

function renderEmptyState(target, eyebrow, title, body) {
  target.innerHTML = `
    <div class="empty-state">
      <p class="eyebrow">${eyebrow}</p>
      <h3>${title}</h3>
      <p>${body}</p>
    </div>
  `;
}

function renderList() {
  const visible = invoices.filter((invoice) => filter.value === "all" || invoice.status === filter.value);
  list.innerHTML = "";

  if (visible.length === 0) {
    renderEmptyState(
      list,
      "No live invoices",
      "Connect the ledger before invoice work starts.",
      "The queue is intentionally empty until the Phoenix billing API and PostgreSQL ledger are wired into this surface."
    );
    selectedId = null;
    return;
  }

  for (const invoice of visible) {
    const row = document.createElement("button");
    row.type = "button";
    row.className = "invoice-row";
    row.setAttribute("aria-selected", String(invoice.id === selectedId));
    row.innerHTML = `
      <span><strong>${invoice.number}</strong><br>${invoice.customer}</span>
      <span>${invoice.total}</span>
      <span>${invoice.due}</span>
      <span class="badge ${invoice.status}">${invoice.status.replace("_", " ")}</span>
    `;
    row.addEventListener("click", () => {
      selectedId = invoice.id;
      renderList();
      renderDetail();
    });
    list.appendChild(row);
  }

  if (!visible.find((invoice) => invoice.id === selectedId) && visible[0]) {
    selectedId = visible[0].id;
    renderDetail();
  }
}

function renderDetail() {
  const invoice = selectedId ? invoices.find((candidate) => candidate.id === selectedId) : undefined;
  if (!invoice) {
    detail.innerHTML = `
      <div class="integration-list">
        ${integrationReadiness.map((item) => `
          <div class="status-line" data-tone="${item.tone}">
            <span>${item.label}</span>
            <strong>${item.state}</strong>
          </div>
        `).join("")}
      </div>
    `;
    return;
  }

  detail.innerHTML = `
    <div class="detail-card">
      <h2>${invoice.number}</h2>
      <p>${invoice.customer}<br><span class="muted">${invoice.project}</span></p>
      <div class="detail-total"><span>Total</span><strong>${invoice.total}</strong></div>
      <div class="detail-total"><span>Balance due</span><strong>${invoice.balance}</strong></div>
      <p><strong>Next action:</strong> ${invoice.next}</p>
      <button class="primary" type="button">${invoice.next}</button>
    </div>
  `;
}

filter.addEventListener("change", renderList);

document.querySelector("#new-invoice").addEventListener("click", () => {
  dialog.showModal();
});

document.querySelector("#copy-link").addEventListener("click", async () => {
  const target = `${location.href.split("#")[0]}#billing-setup`;
  await navigator.clipboard?.writeText(target);
});

renderList();
renderDetail();
