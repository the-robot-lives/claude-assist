"use client";

import { useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";
import { AuthCard, AuthFooterLink } from "@/components/auth-card";

export default function SignupPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await register(email, password, inviteToken);
      router.push("/app");
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Registration failed");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthCard
      title="Sign Up"
      cyId="signup"
      error={error}
      footer={<AuthFooterLink prompt="Already have an account?" href="/login" label="Log in" cy="login-link" />}
    >
        <form onSubmit={handleSubmit} data-cy="auth-form" data-cy-id="signup">
          <div className="sg-field">
            <label htmlFor="invite-token">Invite Token</label>
            <input
              id="invite-token"
              data-cy="invite-token-input"
              type="text"
              value={inviteToken}
              onChange={(e) => setInviteToken(e.target.value)}
              required
              autoComplete="off"
            />
          </div>
          <div className="sg-field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              data-cy="email-input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
          </div>
          <div className="sg-field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              data-cy="password-input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              autoComplete="new-password"
            />
          </div>
          <button type="submit" className="sg-btn sg-btn--black" data-cy="submit-signup" disabled={loading}>
            {loading ? "Creating account..." : "Sign Up"}
          </button>
        </form>
    </AuthCard>
  );
}
