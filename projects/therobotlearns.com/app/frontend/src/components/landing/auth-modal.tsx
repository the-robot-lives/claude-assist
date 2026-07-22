"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/context/auth";
import { postAuthPath } from "@/lib/auth-flow";
import { getRuntimeConfig } from "@/lib/runtime-config";

const AUTHENTIK_URL = "/auth/oidc";
const INVITE_PATTERN = /^TRL-[A-Z0-9-]{6,}$/i;

export type AuthMode = "login" | "signup";

interface AuthModalProps {
  mode: AuthMode | null;
  onClose: () => void;
}

interface StatusState {
  state: "ok" | "error";
  message: string;
}

function apiBase() {
  return getRuntimeConfig().API_URL || process.env.NEXT_PUBLIC_API_URL || "";
}

export function AuthModal({ mode, onClose }: AuthModalProps) {
  const router = useRouter();
  const { login } = useAuth();
  const dialogRef = useRef<HTMLDialogElement>(null);

  const [tab, setTab] = useState<AuthMode>("signup");
  const [signupStatus, setSignupStatus] = useState<StatusState | null>(null);
  const [signupSubmitting, setSignupSubmitting] = useState(false);
  const [loginStatus, setLoginStatus] = useState<StatusState | null>(null);
  const [loginSubmitting, setLoginSubmitting] = useState(false);

  // Open/close the native <dialog> in response to the parent-controlled mode.
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (mode) {
      setTab(mode);
      if (!dialog.open) dialog.showModal();
      // Focus the first field of the active tab once it renders.
      requestAnimationFrame(() => {
        dialog.querySelector<HTMLElement>(".auth-form.is-active input")?.focus();
      });
    } else if (dialog.open) {
      dialog.close();
    }
  }, [mode]);

  function handleTab(next: AuthMode) {
    setTab(next);
    requestAnimationFrame(() => {
      dialogRef.current?.querySelector<HTMLElement>(".auth-form.is-active input")?.focus();
    });
  }

  async function handleSignup(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const data = new FormData(form);
    const email = String(data.get("email") || "").trim();
    const invite = String(data.get("invite") || "").trim();
    const focus = String(data.get("focus") || "").trim();

    if (!email || !email.includes("@")) {
      setSignupStatus({ state: "error", message: "Enter a valid email address." });
      return;
    }

    if (invite && !INVITE_PATTERN.test(invite)) {
      setSignupStatus({
        state: "error",
        message: "Invite tokens look like TRL-XXXXXX. Leave the field blank to join the waitlist.",
      });
      return;
    }

    if (!focus) {
      setSignupStatus({ state: "error", message: "Choose a learning focus for onboarding." });
      return;
    }

    setSignupSubmitting(true);
    setSignupStatus(null);
    try {
      const res = await fetch(`${apiBase()}/api/v1/waitlist`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, invite, focus }),
      });
      const body = await res.json().catch(() => ({}));

      if (!res.ok) {
        setSignupStatus({
          state: "error",
          message: body.error || "Something went wrong. Please try again.",
        });
        return;
      }

      const invited = body.status === "invited";
      setSignupStatus({
        state: "ok",
        message: invited
          ? "Invite accepted — direct beta access is staged. Authentik users can continue without a token."
          : "You're on the beta waitlist. Authentik users can continue without waiting.",
      });
      form.reset();
    } catch {
      setSignupStatus({ state: "error", message: "Something went wrong. Please try again." });
    } finally {
      setSignupSubmitting(false);
    }
  }

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const email = String(data.get("email") || "").trim();
    const password = String(data.get("password") || "");

    setLoginSubmitting(true);
    setLoginStatus(null);
    try {
      const user = await login(email, password);
      router.push(postAuthPath(user));
    } catch {
      setLoginStatus({ state: "error", message: "Invalid email or password." });
    } finally {
      setLoginSubmitting(false);
    }
  }

  return (
    <dialog
      ref={dialogRef}
      className="auth-dialog"
      id="auth-dialog"
      aria-labelledby="auth-title"
      onClose={onClose}
    >
      <form method="dialog" className="dialog-close-form">
        <button className="icon-button" value="close" aria-label="Close dialog">
          x
        </button>
      </form>

      <div className="auth-layout">
        <section className="auth-panel">
          <p className="eyebrow">Account access</p>
          <h2 id="auth-title">Log in with Authentik</h2>
          <p>
            Authentik is the primary identity path for beta users. It does not require a separate invite token.
          </p>
          <a
            className="button button-primary button-block"
            href={AUTHENTIK_URL}
            onClick={() => {
              try {
                sessionStorage.setItem("trl-auth-method", "authentik");
              } catch {
                /* sessionStorage may be unavailable; navigation still proceeds. */
              }
            }}
          >
            Continue with Authentik
          </a>
          <p className="small-note">You will be redirected to the configured Authentik application.</p>
        </section>

        <section className="auth-panel auth-panel-muted">
          <div className="auth-tabs" role="tablist" aria-label="Beta access forms">
            <button
              className={`auth-tab${tab === "signup" ? " is-active" : ""}`}
              type="button"
              role="tab"
              aria-selected={tab === "signup"}
              onClick={() => handleTab("signup")}
            >
              Join waitlist
            </button>
            <button
              className={`auth-tab${tab === "login" ? " is-active" : ""}`}
              type="button"
              role="tab"
              aria-selected={tab === "login"}
              onClick={() => handleTab("login")}
            >
              Email login
            </button>
          </div>

          <form
            className={`auth-form${tab === "signup" ? " is-active" : ""}`}
            id="signup-form"
            onSubmit={handleSignup}
            noValidate
          >
            <label>
              Work email
              <input name="email" type="email" autoComplete="email" required />
            </label>
            <label>
              Invite token (optional)
              <input
                name="invite"
                type="text"
                autoComplete="one-time-code"
                inputMode="text"
                placeholder="TRL-... for direct beta access"
              />
            </label>
            <label>
              Learning focus
              <select name="focus" required defaultValue="">
                <option value="">Choose one</option>
                <option>AI engineering</option>
                <option>Systems architecture</option>
                <option>Team enablement</option>
                <option>Personal study loop</option>
              </select>
            </label>
            <button
              className="button button-primary button-block"
              type="submit"
              disabled={signupSubmitting}
            >
              {signupSubmitting ? "Joining..." : "Join the beta waitlist"}
            </button>
            <p
              className="form-status"
              id="signup-status"
              aria-live="polite"
              data-state={signupStatus?.state}
            >
              {signupStatus?.message}
            </p>
          </form>

          <form
            className={`auth-form${tab === "login" ? " is-active" : ""}`}
            id="login-form"
            onSubmit={handleLogin}
            noValidate
          >
            <label>
              Email
              <input name="email" type="email" autoComplete="email" required />
            </label>
            <label>
              Password
              <input name="password" type="password" autoComplete="current-password" required />
            </label>
            <button
              className="button button-secondary button-block"
              type="submit"
              disabled={loginSubmitting}
            >
              {loginSubmitting ? "Logging in..." : "Log in with email"}
            </button>
            <p
              className="form-status"
              id="login-status"
              aria-live="polite"
              data-state={loginStatus?.state}
            >
              {loginStatus?.message}
            </p>
          </form>
        </section>
      </div>
    </dialog>
  );
}
