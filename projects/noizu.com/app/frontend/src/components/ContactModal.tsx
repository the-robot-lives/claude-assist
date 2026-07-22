"use client";

import { useState, useEffect, useCallback, useRef } from "react";

interface ContactModalProps {
  open: boolean;
  onClose: () => void;
}

// Contact submissions flow to the foryou signup service (foryou.therobotlives.com).
// TODO(provisioning): the foryou List with public_slug `noizu-contact` must be
// provisioned (via foryou's management API / TF provider) with matching typed
// attributes — company:string, project_type:select, budget_range:select,
// timeline:select — before this goes live. Until then the public signup endpoint
// still returns 202 and drops unknown attribs harmlessly.
const FORYOU_BASE_URL = "https://foryou.therobotlives.com";
const NOIZU_CONTACT_LIST_SLUG = "noizu-contact";

const PROJECT_TYPE_OPTIONS = [
  "Consulting",
  "Product/App",
  "AI/ML",
  "Infrastructure",
  "Collaboration",
  "Other",
];
const BUDGET_RANGE_OPTIONS = ["<$10k", "$10–50k", "$50–100k", "$100k+", "Not sure"];
const TIMELINE_OPTIONS = ["ASAP", "1–3 months", "3–6 months", "6+ months", "Exploring"];

const fieldClass =
  "w-full px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-white text-sm placeholder:text-zinc-500 focus:outline-none focus:border-gold-400/50 focus:ring-1 focus:ring-gold-400/25 transition-colors";
const selectClass = `${fieldClass} appearance-none bg-no-repeat cursor-pointer`;

export function ContactModal({ open, onClose }: ContactModalProps) {
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle");
  const [errorMsg, setErrorMsg] = useState("");
  const formRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [open, onClose]);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("sending");
    setErrorMsg("");

    const form = formRef.current;
    if (!form) return;

    const formData = new FormData(form);
    const email = (formData.get("email") as string) ?? "";
    const name = (formData.get("name") as string) ?? "";
    const inquiry = (formData.get("inquiry") as string) ?? "";
    const companyWebsite = (formData.get("company_website") as string) ?? "";

    // Structured optional fields → foryou List Attributes (typed), keyed by attribute slug.
    // Only include non-empty values so the signup's attribs jsonb stays clean.
    // The foryou public endpoint reads the identity email (and all attributes)
    // from INSIDE `values`, keyed by attribute slug — a top-level `email` is
    // dropped. So email/name go into `values`, not alongside it.
    const values: Record<string, string> = {};
    const setValue = (slug: string, raw: FormDataEntryValue | null) => {
      const v = typeof raw === "string" ? raw.trim() : "";
      if (v) values[slug] = v;
    };
    if (email.trim()) values.email = email.trim();
    if (name.trim()) values.name = name.trim();
    setValue("company", formData.get("company"));
    setValue("project_type", formData.get("project_type"));
    setValue("budget_range", formData.get("budget_range"));
    setValue("timeline", formData.get("timeline"));
    if (inquiry.trim()) values.inquiry = inquiry.trim();

    try {
      const res = await fetch(
        `${FORYOU_BASE_URL}/api/v1/public/lists/${NOIZU_CONTACT_LIST_SLUG}/signups`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            values, // email + name + optional attrs, all keyed by slug
            source: "noizu-website-contact",
            company_website: companyWebsite, // honeypot — expected empty
          }),
        },
      );

      // The public signup endpoint always returns 202; treat any 2xx as success.
      if (!res.ok) {
        const data = await res.json().catch(() => null);
        throw new Error(data?.message || `Request failed (${res.status})`);
      }

      setStatus("sent");
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Something went wrong.");
      setStatus("error");
    }
  };

  const handleClose = useCallback(() => {
    if (status === "sending") return;
    onClose();
    setTimeout(() => {
      setStatus("idle");
      setErrorMsg("");
      formRef.current?.reset();
    }, 200);
  }, [status, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={handleClose}>
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />
      <div
        className="relative glass glow rounded-2xl w-full max-w-lg"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 text-zinc-400 hover:text-white transition-colors"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <div className="p-8 sm:p-10">
          {status === "sent" ? (
            <div className="text-center py-8">
              <div className="w-12 h-12 rounded-full bg-gold-400/20 flex items-center justify-center mx-auto mb-4">
                <svg className="w-6 h-6 text-gold-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-white mb-2">Message sent</h3>
              <p className="text-sm text-zinc-400">I&apos;ll get back to you soon.</p>
            </div>
          ) : (
            <>
              <h3 className="text-xl font-semibold text-white mb-1">Get in Touch</h3>
              <p className="text-sm text-zinc-400 mb-6">Tell me about your project or challenge.</p>
              <form
                ref={formRef}
                onSubmit={handleSubmit}
                className="space-y-4"
              >
                {/* Honeypot — hidden from users; bots that fill it are flagged by foryou. */}
                <input
                  type="text"
                  name="company_website"
                  tabIndex={-1}
                  autoComplete="off"
                  aria-hidden="true"
                  className="hidden"
                />
                <div>
                  <label htmlFor="contact-name" className="block text-sm text-zinc-300 mb-1.5">Name</label>
                  <input
                    id="contact-name"
                    type="text"
                    name="name"
                    required
                    className={fieldClass}
                    placeholder="Your name"
                  />
                </div>
                <div>
                  <label htmlFor="contact-email" className="block text-sm text-zinc-300 mb-1.5">Email</label>
                  <input
                    id="contact-email"
                    type="email"
                    name="email"
                    required
                    className={fieldClass}
                    placeholder="you@example.com"
                  />
                </div>
                <div>
                  <label htmlFor="contact-inquiry" className="block text-sm text-zinc-300 mb-1.5">Inquiry</label>
                  <textarea
                    id="contact-inquiry"
                    name="inquiry"
                    rows={4}
                    className={`${fieldClass} resize-none`}
                    placeholder="Tell me about your project..."
                  />
                </div>

                <div className="pt-1 border-t border-white/5">
                  <p className="text-xs uppercase tracking-wide text-zinc-500 mt-4 mb-3">
                    A few optional details
                  </p>
                  <div className="space-y-4">
                    <div>
                      <label htmlFor="contact-company" className="block text-sm text-zinc-300 mb-1.5">
                        Company / Organization <span className="text-zinc-500">(optional)</span>
                      </label>
                      <input
                        id="contact-company"
                        type="text"
                        name="company"
                        className={fieldClass}
                        placeholder="Acme Inc."
                      />
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="contact-project-type" className="block text-sm text-zinc-300 mb-1.5">
                          Project type <span className="text-zinc-500">(optional)</span>
                        </label>
                        <select id="contact-project-type" name="project_type" defaultValue="" className={selectClass}>
                          <option value="" className="bg-zinc-900">Select…</option>
                          {PROJECT_TYPE_OPTIONS.map((opt) => (
                            <option key={opt} value={opt} className="bg-zinc-900">{opt}</option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label htmlFor="contact-budget" className="block text-sm text-zinc-300 mb-1.5">
                          Budget range <span className="text-zinc-500">(optional)</span>
                        </label>
                        <select id="contact-budget" name="budget_range" defaultValue="" className={selectClass}>
                          <option value="" className="bg-zinc-900">Select…</option>
                          {BUDGET_RANGE_OPTIONS.map((opt) => (
                            <option key={opt} value={opt} className="bg-zinc-900">{opt}</option>
                          ))}
                        </select>
                      </div>
                    </div>
                    <div>
                      <label htmlFor="contact-timeline" className="block text-sm text-zinc-300 mb-1.5">
                        Timeline <span className="text-zinc-500">(optional)</span>
                      </label>
                      <select id="contact-timeline" name="timeline" defaultValue="" className={selectClass}>
                        <option value="" className="bg-zinc-900">Select…</option>
                        {TIMELINE_OPTIONS.map((opt) => (
                          <option key={opt} value={opt} className="bg-zinc-900">{opt}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>

                {status === "error" && (
                  <p className="text-sm text-red-400">{errorMsg || "Something went wrong. Please try again."}</p>
                )}
                <button
                  type="submit"
                  disabled={status === "sending"}
                  className="w-full py-3 bg-gold-400 hover:bg-gold-300 disabled:opacity-50 disabled:cursor-not-allowed text-black text-sm font-medium rounded-xl transition-colors"
                >
                  {status === "sending" ? "Sending..." : "Send Message"}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
