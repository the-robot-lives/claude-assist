"use client";

import { useEffect } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";

// ⟦𓂵𓌨𓍬𓆨⟧ PendingApprovalPage :: auto-generated pointer for public function PendingApprovalPage
export default function PendingApprovalPage() {
  const { user, loading, logout } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) router.push("/login");
    if (!loading && user && user.status !== "pending" && user.status !== "waitlist") router.push("/app");
  }, [loading, router, user]);

  if (loading || !user) return null;

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Pending Approval</h1>
        <p className="sg-page-intro">
          Your account is registered and waiting for manual approval.
        </p>
        <button type="button" className="sg-btn sg-btn--outline" onClick={logout}>
          Log Out
        </button>
      </main>
    </div>
  );
}
