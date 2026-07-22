"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { NavBar } from "../../navbar";
import { Footer } from "@/components/footer";
import { api, type DirectorySite, type SiteClaim } from "@/lib/api";
import { isAuthed } from "@/lib/session";

type Method = "meta_tag" | "dns_txt";

function CopyBlock({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* clipboard unavailable — the value is still selectable */
    }
  }

  return (
    <div>
      <p className="mb-1.5 font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary">
        {label}
      </p>
      <div className="flex items-stretch gap-2">
        <code className="min-w-0 flex-1 overflow-x-auto rounded-xl bg-sunken px-4 py-3 font-mono text-sm text-ink">
          {value}
        </code>
        <button
          type="button"
          onClick={copy}
          className="shrink-0 rounded-xl border-2 border-rule bg-surface px-4 font-ui text-xs font-semibold text-ink-secondary transition-colors duration-150 hover:border-coral hover:text-ink"
        >
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
    </div>
  );
}

export default function ClaimPage() {
  const router = useRouter();
  const params = useParams<{ slug: string }>();
  const slug = params.slug;

  const [ready, setReady] = useState(false);
  const [site, setSite] = useState<DirectorySite | null>(null);
  const [siteStatus, setSiteStatus] = useState<"loading" | "ok" | "notfound">("loading");

  const [method, setMethod] = useState<Method>("meta_tag");
  const [claim, setClaim] = useState<SiteClaim | null>(null);
  const [starting, setStarting] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [verifyResult, setVerifyResult] = useState<SiteClaim["status"] | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!isAuthed()) {
      router.replace(`/login?next=/claim/${slug}`);
      return;
    }
    setReady(true);
    api
      .directorySite(slug)
      .then((r) => {
        setSite(r.site);
        setSiteStatus("ok");
      })
      .catch(() => setSiteStatus("notfound"));
  }, [router, slug]);

  async function startClaim() {
    setError("");
    setVerifyResult(null);
    setStarting(true);
    try {
      const { claim: c } = await api.claimSite(slug, method);
      setClaim(c);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't start the claim. Try again.");
    } finally {
      setStarting(false);
    }
  }

  async function verify() {
    if (!claim) return;
    setError("");
    setVerifying(true);
    try {
      const { claim: c } = await api.verifyClaim(claim.id);
      // Success ⇒ backend set status to "verified"; the claim now owns the site.
      setVerifyResult(c.status ?? "pending");
    } catch (err) {
      // Failure ⇒ backend returns 422 {error:"Verification failed", reason} and
      // leaves the claim pending; request<T> surfaces the `error` string.
      setVerifyResult(null);
      setError(
        err instanceof Error
          ? `${err.message} — the token isn't visible on your site yet. Give DNS or page caches a moment, then verify again.`
          : "Verification request failed. Try again.",
      );
    } finally {
      setVerifying(false);
    }
  }

  if (!ready || siteStatus === "loading") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading…
        </p>
      </div>
    );
  }

  if (siteStatus === "notfound" || !site) {
    return (
      <div className="min-h-screen bg-cream">
        <NavBar />
        <section className="px-6 py-20">
          <div className="mx-auto max-w-[960px] text-center">
            <h1
              className="font-display text-3xl font-semibold tracking-tight text-ink"
              style={{ fontVariationSettings: "'WONK' 1" }}
            >
              Site not found.
            </h1>
            <Link
              href="/"
              className="mt-6 inline-block font-ui text-sm font-semibold text-olive hover:text-olive-hover"
            >
              &larr; Back to the directory
            </Link>
          </div>
        </section>
        <Footer />
      </div>
    );
  }

  // Snippets must match exactly what the backend `verify_claim` looks for:
  // meta_tag → <meta name="gotta-cc" content="TOKEN">; dns_txt → gotta-cc=TOKEN.
  const metaSnippet = claim ? `<meta name="gotta-cc" content="${claim.token}">` : "";
  const dnsSnippet = claim ? `gotta-cc=${claim.token}` : "";

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-12">
        <div className="mx-auto max-w-2xl">
          <Link
            href={`/site/${site.slug}`}
            className="font-ui text-xs font-semibold text-olive hover:text-olive-hover transition-colors duration-150"
          >
            &larr; {site.name}
          </Link>

          <p className="mb-3 mt-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Claim ownership
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Verify you own {site.domain}
          </h1>
          <p className="mt-3 max-w-[60ch] font-body text-base leading-relaxed text-ink-secondary">
            Prove ownership by adding a verification token to the site — either a
            meta tag on the homepage or a DNS TXT record on the domain. Once it&apos;s
            in place, verify below.
          </p>

          {/* Method toggle */}
          <div className="mt-8 inline-flex rounded-xl border-2 border-rule bg-surface p-1">
            {(["meta_tag", "dns_txt"] as Method[]).map((m) => (
              <button
                key={m}
                type="button"
                onClick={() => setMethod(m)}
                className={`rounded-lg px-4 py-2 font-ui text-sm font-semibold transition-colors duration-150 ${
                  method === m
                    ? "bg-coral text-white"
                    : "text-ink-secondary hover:text-ink"
                }`}
              >
                {m === "meta_tag" ? "Meta tag" : "DNS TXT record"}
              </button>
            ))}
          </div>

          <div className="mt-6">
            <button
              type="button"
              onClick={startClaim}
              disabled={starting}
              className="rounded-xl bg-coral px-6 py-3 font-ui text-base font-semibold text-white shadow-[0_2px_8px_rgba(232,112,74,0.2)] transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover disabled:opacity-50"
            >
              {starting
                ? "Generating token…"
                : claim
                  ? "Regenerate token"
                  : "Start verification"}
            </button>
          </div>

          {error && (
            <p className="mt-4 font-ui text-sm text-error" role="alert">
              {error}
            </p>
          )}

          {claim && (
            <div className="mt-8 flex flex-col gap-5 rounded-2xl bg-surface p-6 shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
              <div>
                <p className="font-display text-lg font-semibold text-ink" style={{ fontVariationSettings: "'WONK' 1" }}>
                  {claim.method === "dns_txt"
                    ? "Add this DNS TXT record"
                    : "Add this meta tag to your homepage"}
                </p>
                <p className="mt-2 font-body text-sm leading-relaxed text-ink-secondary">
                  {claim.method === "dns_txt"
                    ? "Add a DNS TXT record at your domain root with this value, then click verify."
                    : "Add this tag inside the <head> of your site's homepage, then click verify."}
                </p>
              </div>

              {claim.method === "dns_txt" ? (
                <>
                  <CopyBlock label={`TXT record on ${site.domain}`} value={dnsSnippet} />
                  <CopyBlock label="Token" value={claim.token} />
                </>
              ) : (
                <CopyBlock label="Meta tag" value={metaSnippet} />
              )}

              <div className="flex flex-wrap items-center gap-4 border-t border-rule pt-5">
                <button
                  type="button"
                  onClick={verify}
                  disabled={verifying}
                  className="rounded-xl bg-olive px-5 py-2.5 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-olive-hover disabled:opacity-50"
                >
                  {verifying ? "Checking…" : "Verify now"}
                </button>

                {verifyResult === "verified" && (
                  <span className="font-ui text-sm font-semibold text-olive">
                    Verified — you now own this listing.
                  </span>
                )}
                {verifyResult === "pending" && (
                  <span className="font-ui text-sm font-semibold text-ink-secondary">
                    Still pending — the token isn&apos;t visible yet.
                  </span>
                )}
              </div>
            </div>
          )}
        </div>
      </section>

      <Footer />
    </div>
  );
}
