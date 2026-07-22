"use client";

import { useEffect, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/context/auth";
import { AnnouncerProvider } from "./Announcer";
import styles from "./preference-center.module.css";

/**
 * Account-scoped guard for the preference center. Waits for auth to resolve,
 * redirects unauthenticated visitors to /login (preserving the return path),
 * and provides the aria-live announcer. Does NOT require an org (D12).
 */
export function AuthGate({
  next,
  children,
}: {
  next: string;
  children: ReactNode;
}) {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.replace(`/login?next=${encodeURIComponent(next)}`);
    }
  }, [loading, user, router, next]);

  if (loading) {
    return (
      <div className={styles.page}>
        <div className={styles.skeleton} aria-hidden="true">
          <div className={styles.skelRow} />
          <div className={styles.skelRow} />
          <div className={styles.skelRow} />
        </div>
        <span className={styles.srOnly} role="status" aria-live="polite">
          Loading your preferences…
        </span>
      </div>
    );
  }

  if (!user) return null;

  return <AnnouncerProvider>{children}</AnnouncerProvider>;
}
