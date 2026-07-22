const AUTHENTIK_URL = "/auth/oidc";
const INVITE_PATTERN = /^TRL-[A-Z0-9-]{6,}$/i;

const dialog = document.querySelector("#auth-dialog");
const openButtons = document.querySelectorAll("[data-open-auth]");
const tabs = document.querySelectorAll("[data-auth-tab]");
const forms = document.querySelectorAll("[data-auth-form]");
const signupForm = document.querySelector("#signup-form");
const loginForm = document.querySelector("#login-form");
const signupStatus = document.querySelector("#signup-status");
const loginStatus = document.querySelector("#login-status");

let lastTrigger = null;

function activateTab(tabName) {
  tabs.forEach((tab) => {
    const active = tab.dataset.authTab === tabName;
    tab.classList.toggle("is-active", active);
    tab.setAttribute("aria-selected", String(active));
  });

  forms.forEach((form) => {
    form.classList.toggle("is-active", form.dataset.authForm === tabName);
  });
}

function openAuth(mode) {
  lastTrigger = document.activeElement;
  activateTab(mode === "login" ? "login" : "signup");
  dialog.showModal();
  const firstInput = dialog.querySelector(".auth-form.is-active input");
  firstInput?.focus();
}

openButtons.forEach((button) => {
  button.addEventListener("click", () => openAuth(button.dataset.openAuth));
});

tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    activateTab(tab.dataset.authTab);
    dialog.querySelector(".auth-form.is-active input")?.focus();
  });
});

dialog.addEventListener("close", () => {
  if (lastTrigger && typeof lastTrigger.focus === "function") {
    lastTrigger.focus();
  }
});

dialog.addEventListener("keydown", (event) => {
  if (event.key !== "Tab") return;
  const focusable = dialog.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0];
  const last = focusable[focusable.length - 1];

  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
});

document.querySelectorAll(`a[href="${AUTHENTIK_URL}"]`).forEach((link) => {
  link.addEventListener("click", () => {
    sessionStorage.setItem("trl-auth-method", "authentik");
  });
});

signupForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const data = new FormData(signupForm);
  const email = String(data.get("email") || "").trim();
  const invite = String(data.get("invite") || "").trim();
  const focus = String(data.get("focus") || "").trim();

  signupStatus.removeAttribute("data-state");

  if (!email || !email.includes("@")) {
    signupStatus.dataset.state = "error";
    signupStatus.textContent = "Enter a valid email address.";
    return;
  }

  if (!INVITE_PATTERN.test(invite)) {
    signupStatus.dataset.state = "error";
    signupStatus.textContent = "Direct beta signup requires a valid invite token.";
    return;
  }

  if (!focus) {
    signupStatus.dataset.state = "error";
    signupStatus.textContent = "Choose a learning focus for onboarding.";
    return;
  }

  const request = {
    email,
    invite,
    focus,
    requestedAt: new Date().toISOString()
  };
  localStorage.setItem("trl-beta-request", JSON.stringify(request));
  signupStatus.dataset.state = "ok";
  signupStatus.textContent = "Beta request staged. Authentik users can continue without an invite token.";
});

loginForm.addEventListener("submit", (event) => {
  event.preventDefault();
  loginStatus.dataset.state = "error";
  loginStatus.textContent = "Email login needs the account backend. Use Authentik for active beta access.";
});
