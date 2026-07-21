"use client";

import { useState } from "react";
import { getRuntimeConfig } from "@/lib/runtime-config";

type FormStatus = "idle" | "sending" | "sent" | "error";

interface InquiryResponse {
  inquiry?: {
    id: string;
    status: string;
  };
  error?: string;
  errors?: Record<string, string[]>;
}

function apiBaseUrl() {
  return getRuntimeConfig().API_URL || process.env.NEXT_PUBLIC_API_URL || "";
}

function errorMessage(data: InquiryResponse | null, status: number) {
  if (data?.error) return data.error;
  if (data?.errors) {
    const first = Object.entries(data.errors)[0];
    if (first) return `${first[0]} ${first[1][0]}`;
  }
  return `Request failed (${status})`;
}

export function InquiryForm() {
  const [status, setStatus] = useState<FormStatus>("idle");
  const [error, setError] = useState("");

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("sending");
    setError("");

    const form = event.currentTarget;
    const formData = new FormData(form);

    try {
      const response = await fetch(`${apiBaseUrl()}/api/v1/inquiries`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: formData.get("name"),
          email: formData.get("email"),
          message: formData.get("message"),
          source: "foryou-home",
          page_url: window.location.href,
          referrer: document.referrer,
          campaign: formData.get("intent"),
          user_agent: navigator.userAgent,
        }),
      });

      const data = (await response.json().catch(() => null)) as InquiryResponse | null;

      if (!response.ok) {
        throw new Error(errorMessage(data, response.status));
      }

      form.reset();
      setStatus("sent");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to send inquiry.");
      setStatus("error");
    }
  }

  return (
    <form className="fy-form" onSubmit={handleSubmit}>
      <div className="fy-form__row">
        <div className="sg-field">
          <label htmlFor="inquiry-name">Name</label>
          <input id="inquiry-name" name="name" type="text" required autoComplete="name" />
        </div>
        <div className="sg-field">
          <label htmlFor="inquiry-email">Email</label>
          <input id="inquiry-email" name="email" type="email" required autoComplete="email" />
        </div>
      </div>

      <div className="sg-field">
        <label htmlFor="inquiry-intent">What should foryou handle?</label>
        <select id="inquiry-intent" name="intent" defaultValue="portfolio-contact">
          <option value="portfolio-contact">Portfolio contact form</option>
          <option value="waitlist">Waitlist or launch signup</option>
          <option value="newsletter">Newsletter preferences</option>
          <option value="custom">Custom intake workflow</option>
        </select>
      </div>

      <div className="sg-field">
        <label htmlFor="inquiry-message">Message</label>
        <textarea
          id="inquiry-message"
          name="message"
          rows={5}
          required
          placeholder="Tell me which site, list, or contact flow you want routed through foryou."
        />
      </div>

      {status === "error" && <p className="sg-error">{error}</p>}
      {status === "sent" && (
        <p className="fy-form__success">Inquiry captured. It is now in the foryou intake queue.</p>
      )}

      <button type="submit" className="sg-btn sg-btn--black fy-form__submit" disabled={status === "sending"}>
        {status === "sending" ? "Sending..." : "Send inquiry"}
      </button>
    </form>
  );
}
