"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

// Signups flow to the foryou signup service (foryou.therobotlives.com).
// The foryou List with this public_slug must be provisioned before go-live —
// see projects/foryou.therobotlives.com/provisioning/.
const FORYOU_BASE_URL = "https://foryou.therobotlives.com";
const FORYOU_LIST_SLUG = "robots-unite-waitlist";

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
      <div className="rounded-card border border-success/30 bg-success-muted p-6 text-center">
        <p className="font-medium text-text-primary">
          You&apos;re on the list.
        </p>
        <p className="mt-1 text-sm text-text-secondary">
          Check your inbox to confirm your subscription.
        </p>
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex flex-col gap-3 sm:flex-row"
    >
      <div className="flex flex-1 flex-col gap-1">
        <Input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@company.com"
          required
          disabled={status === "loading"}
          className="flex-1"
        />
        {status === "error" && (
          <p className="text-xs text-error">{errorMsg}</p>
        )}
      </div>
      <Button type="submit" size="md" disabled={status === "loading"}>
        {status === "loading" ? "Subscribing..." : buttonText}
      </Button>
    </form>
  );
}
