"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/context/auth";
import { api } from "@/lib/api";
import { appUrl, postAuthPath, userPendingApproval } from "@/lib/auth-flow";
import { useRouter } from "next/navigation";

// ⟦𓎷𓇿𓊊𓁉⟧ CompleteRegistrationPage :: auto-generated pointer for public function CompleteRegistrationPage
export default function CompleteRegistrationPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [userName, setUserName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [mobilePhone, setMobilePhone] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
    if (user) {
      setUserName(user.user_name || user.email.split("@")[0] || "");
      setMobilePhone(user.mobile_phone || "");
    }
  }, [loading, router, user]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      const res = await api.completeRegistration({
        userName,
        firstName,
        lastName,
        mobilePhone,
        inviteToken,
      });
      router.push(userPendingApproval(res.user) ? "/pending-approval" : appUrl("/app"));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to complete registration");
    } finally {
      setSaving(false);
    }
  }

  if (loading || !user) return null;

  if (!user.requires_profile_completion && !userPendingApproval(user)) {
    router.push(postAuthPath(user));
    return null;
  }

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Complete Registration</h1>
        <form onSubmit={handleSubmit} style={{ maxWidth: 420 }}>
          {error && <p className="sg-error">{error}</p>}
          <div className="sg-field">
            <label htmlFor="invite-token">Invite Token</label>
            <input id="invite-token" type="text" value={inviteToken} onChange={(e) => setInviteToken(e.target.value)} autoComplete="off" />
          </div>
          <div className="sg-field">
            <label htmlFor="user-name">User Name</label>
            <input id="user-name" type="text" value={userName} onChange={(e) => setUserName(e.target.value)} required autoComplete="username" />
          </div>
          <div className="sg-field">
            <label htmlFor="first-name">First Name</label>
            <input id="first-name" type="text" value={firstName} onChange={(e) => setFirstName(e.target.value)} required autoComplete="given-name" />
          </div>
          <div className="sg-field">
            <label htmlFor="last-name">Last Name</label>
            <input id="last-name" type="text" value={lastName} onChange={(e) => setLastName(e.target.value)} required autoComplete="family-name" />
          </div>
          <div className="sg-field">
            <label htmlFor="mobile-phone">Mobile</label>
            <input id="mobile-phone" type="tel" value={mobilePhone} onChange={(e) => setMobilePhone(e.target.value)} required autoComplete="tel" />
          </div>
          <button type="submit" className="sg-btn sg-btn--black" disabled={saving}>
            {saving ? "Saving..." : "Continue"}
          </button>
        </form>
      </main>
    </div>
  );
}
