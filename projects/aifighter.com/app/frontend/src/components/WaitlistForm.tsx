"use client";

import { useState } from "react";

// Signups flow to the foryou signup service (foryou.therobotlives.com).
// The foryou List with this public_slug must be provisioned before go-live —
// see projects/foryou.therobotlives.com/provisioning/.
const FORYOU_BASE_URL = "https://foryou.therobotlives.com";
const FORYOU_LIST_SLUG = "aifighter-waitlist";

export default function WaitlistForm({
  buttonText = "Join Waitlist",
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
      <div className="form-success">
        <p>You&apos;re in.</p>
        <span>We&apos;ll notify you when the arena opens.</span>
      </div>
    );
  }

  return (
    <>
      {status === "error" && (
        <div className="form-error">
          <p>{errorMsg}</p>
        </div>
      )}
      <form className="email-form" onSubmit={handleSubmit}>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@email.com"
          required
          disabled={status === "loading"}
          aria-label="Email address"
        />
        <button type="submit" disabled={status === "loading"}>
          {status === "loading" ? "Joining..." : buttonText}
        </button>
      </form>
    </>
  );
}
