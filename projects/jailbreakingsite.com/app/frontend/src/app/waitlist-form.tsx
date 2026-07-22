"use client";

import { useState } from "react";

// Signups flow to the foryou signup service (foryou.therobotlives.com).
// The foryou List with this public_slug must be provisioned before go-live —
// see projects/foryou.therobotlives.com/provisioning/.
const FORYOU_BASE_URL = "https://foryou.therobotlives.com";
const FORYOU_LIST_SLUG = "jailbreaking-waitlist";

export function WaitlistForm({
  buttonText = "JOIN WAITLIST",
}: {
  buttonText?: string;
}) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<
    "idle" | "loading" | "success" | "error"
  >("idle");
  const [errorMsg, setErrorMsg] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("loading");
    setErrorMsg("");

    try {
      const res = await fetch(
        `${FORYOU_BASE_URL}/api/v1/public/lists/${FORYOU_LIST_SLUG}/signups`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            values: { email },
            source: FORYOU_LIST_SLUG,
            company_website: "", // honeypot — expected empty
          }),
        },
      );

      if (res.ok) {
        setStatus("success");
      } else {
        const data = await res.json().catch(() => null);
        setErrorMsg(data?.message || `Subscription failed (${res.status})`);
        setStatus("error");
      }
    } catch {
      setErrorMsg("Network error — please try again.");
      setStatus("error");
    }
  }

  if (status === "success") {
    return (
      <div className="mx-auto max-w-md rounded border border-accent bg-accent-muted px-4 py-3 text-center">
        <p className="font-mono text-sm font-bold uppercase tracking-widest text-accent">
          [CONFIRMED]
        </p>
        <p className="mt-1 text-xs text-text-secondary">
          Check your inbox to confirm your subscription.
        </p>
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mx-auto flex max-w-lg flex-col gap-3 sm:flex-row"
    >
      <div className="flex flex-1 flex-col gap-1">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="security@yourcompany.com"
          required
          disabled={status === "loading"}
          className="w-full rounded border border-border-strong bg-surface px-3 py-2.5 font-mono text-sm text-text-primary placeholder:text-text-tertiary transition-[border-color,box-shadow] duration-100 focus:border-accent focus:shadow-[0_0_0_2px_var(--accent-muted)] focus:outline-none disabled:opacity-50"
        />
        {status === "error" && (
          <p className="text-xs text-critical">{errorMsg}</p>
        )}
      </div>
      <button
        type="submit"
        disabled={status === "loading"}
        className="rounded bg-accent px-5 py-2.5 font-mono text-sm font-bold uppercase tracking-wider text-[#0B0D0F] transition-colors duration-100 hover:bg-accent-hover disabled:opacity-50"
      >
        {status === "loading" ? "CONNECTING..." : buttonText}
      </button>
    </form>
  );
}
