"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";

function VerifyEmailContent() {
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (!token) {
      setStatus("error");
      setMessage("no verification token provided.");
      return;
    }

    api.verifyEmail(token)
      .then(() => {
        setStatus("success");
        setMessage("your email has been verified successfully.");
      })
      .catch((err) => {
        setStatus("error");
        setMessage(err.message || "verification failed — the link may have expired.");
      });
  }, [token]);

  const tag = status === "loading" ? "[info]" : status === "success" ? "[ok]" : "[err]";
  const tagColor =
    status === "loading" ? "var(--info)" : status === "success" ? "var(--acc)" : "var(--err)";

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 text-center shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline justify-center gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">therobotplans</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-3 font-mono text-lg font-bold text-[var(--ink)]">
          {status === "loading" ? "verifying…" : status === "success" ? "email verified" : "verification failed"}
        </h1>
        <p className="mb-6 font-mono text-[13px]" style={{ color: tagColor }}>
          <span>{tag}</span> {message}
        </p>
        {status !== "loading" && (
          <a
            href={status === "success" ? "/app" : "/login"}
            className="inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)]"
          >
            {status === "success" ? "go to dashboard" : "back to login"}
          </a>
        )}
      </div>
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] font-mono text-sm text-[var(--mut)]">
          loading…
        </div>
      }
    >
      <VerifyEmailContent />
    </Suspense>
  );
}
