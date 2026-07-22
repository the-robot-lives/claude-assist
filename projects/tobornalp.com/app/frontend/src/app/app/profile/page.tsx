"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/context/auth";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Button, FieldLabel, Input, SectionCard } from "@/components/ui";

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
      toast.success("Profile updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Update failed");
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
      toast.success("Password updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Password change failed");
    } finally {
      setSaving(false);
    }
  }

  if (!user) return null;

  return (
    <div className="mx-auto max-w-lg px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold text-text">Profile</h1>

      <div className="flex flex-col gap-6">
        <SectionCard title="Account">
          <form onSubmit={handleProfileUpdate} className="flex flex-col gap-4">
            <FieldLabel label="Username" htmlFor="profile-username">
              <Input
                id="profile-username"
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
              />
            </FieldLabel>
            <FieldLabel label="Email" htmlFor="profile-email">
              <Input
                id="profile-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </FieldLabel>
            <div>
              <Button type="submit" disabled={saving}>
                {saving ? "Saving…" : "Save profile"}
              </Button>
            </div>
          </form>
        </SectionCard>

        <SectionCard title="Change password">
          <form onSubmit={handlePasswordChange} className="flex flex-col gap-4">
            <FieldLabel label="Current password" htmlFor="current-password">
              <Input
                id="current-password"
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                autoComplete="current-password"
              />
            </FieldLabel>
            <FieldLabel label="New password" htmlFor="new-password">
              <Input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                autoComplete="new-password"
              />
            </FieldLabel>
            <div>
              <Button type="submit" disabled={saving || !currentPassword || !newPassword}>
                {saving ? "Saving…" : "Change password"}
              </Button>
            </div>
          </form>
        </SectionCard>
      </div>
    </div>
  );
}
