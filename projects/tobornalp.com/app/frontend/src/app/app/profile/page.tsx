"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/context/auth";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Btn, FieldLabel, Input, SectionCard } from "@/components/ui";

export default function ProfilePage() {
  const { user } = useAuth();
  const [userName, setUserName] = useState("");
  const [email, setEmail] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (user) {
      setUserName(user.user_name || "");
      setEmail(user.email || "");
    }
  }, [user]);

  async function handleProfileUpdate(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      await api.updateProfile({ user_name: userName, email });
      toast.success("profile updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "update failed");
    } finally {
      setSaving(false);
    }
  }

  async function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault();
    if (!currentPassword || !newPassword) return;
    setSaving(true);
    try {
      await api.updateProfile({ current_password: currentPassword, new_password: newPassword });
      setCurrentPassword("");
      setNewPassword("");
      toast.success("password updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "password change failed");
    } finally {
      setSaving(false);
    }
  }

  if (!user) return null;

  return (
    <div className="mx-auto max-w-lg px-4 py-10">
      <h1 className="mb-6 text-[13px] font-bold uppercase tracking-[0.1em] text-ink">profile</h1>

      <div className="flex flex-col gap-4">
        <SectionCard title="account">
          <form onSubmit={handleProfileUpdate} className="flex flex-col gap-4">
            <FieldLabel label="username" htmlFor="profile-username">
              <Input
                id="profile-username"
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                className="rounded-card border-line2 bg-ground"
              />
            </FieldLabel>
            <FieldLabel label="email" htmlFor="profile-email">
              <Input
                id="profile-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="rounded-card border-line2 bg-ground"
              />
            </FieldLabel>
            <div>
              <Btn variant="primary" type="submit" disabled={saving}>
                {saving ? "saving…" : "save profile"}
              </Btn>
            </div>
          </form>
        </SectionCard>

        <SectionCard title="change password">
          <form onSubmit={handlePasswordChange} className="flex flex-col gap-4">
            <FieldLabel label="current password" htmlFor="current-password">
              <Input
                id="current-password"
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                autoComplete="current-password"
                className="rounded-card border-line2 bg-ground"
              />
            </FieldLabel>
            <FieldLabel label="new password" htmlFor="new-password">
              <Input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                autoComplete="new-password"
                className="rounded-card border-line2 bg-ground"
              />
            </FieldLabel>
            <div>
              <Btn variant="primary" type="submit" disabled={saving || !currentPassword || !newPassword}>
                {saving ? "saving…" : "change password"}
              </Btn>
            </div>
          </form>
        </SectionCard>
      </div>
    </div>
  );
}
