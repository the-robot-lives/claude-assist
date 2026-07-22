"use client";

import { useState } from "react";

// Signups flow to the foryou signup service (foryou.therobotlives.com).
// The foryou List with this public_slug must be provisioned before go-live —
// see projects/foryou.therobotlives.com/provisioning/.
const FORYOU_BASE_URL = "https://foryou.therobotlives.com";
const FORYOU_LIST_SLUG = "codefresh-waitlist";

export function WaitlistForm({
  buttonText = "Get Early Access",
}: {
  buttonText?: string;
}) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
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
      <div className="mx-auto max-w-md rounded-md border border-eval-pass bg-eval-pass-muted px-4 py-3 text-center">
        <p className="text-sm font-semibold text-eval-pass">
          You&apos;re on the list!
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
      className="mx-auto flex max-w-md flex-col gap-3 sm:flex-row"
    >
      <div className="flex flex-1 flex-col gap-1">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@company.com"
          required
          disabled={status === "loading"}
          className="w-full rounded-md border border-border bg-surface px-3 py-2.5 text-sm text-text-primary placeholder:text-text-tertiary transition-colors focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent-muted disabled:opacity-50"
        />
        {status === "error" && (
          <p className="text-xs text-eval-fail">{errorMsg}</p>
        )}
      </div>
      <button
        type="submit"
        disabled={status === "loading"}
        className="rounded-md bg-accent px-5 py-2.5 text-sm font-semibold text-[#08090D] transition-opacity hover:opacity-90 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
      >
        {status === "loading" ? "Subscribing..." : buttonText}
      </button>
    </form>
  );
}
