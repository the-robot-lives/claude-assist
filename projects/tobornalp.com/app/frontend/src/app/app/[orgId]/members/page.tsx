"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";
import { toast } from "sonner";
import { Button, Input, Select, Spinner } from "@/components/ui";

interface Member {
  id: string;
  user_id: string;
  email: string;
  user_name: string;
  role: string;
  joined_at: string;
}

const ROLES = ["viewer", "editor", "admin", "owner"];

export default function MembersPage() {
  const { orgId } = useParams<{ orgId: string }>();
  const { user } = useAuth();
  const [members, setMembers] = useState<Member[]>([]);
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteRole, setInviteRole] = useState("viewer");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (orgId) {
      api
        .listMembers(orgId)
        .then((res) => {
          setMembers(res.members);
          setLoading(false);
        })
        .catch(() => setLoading(false));
    }
  }, [orgId]);

  async function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    if (!inviteEmail) return;
    try {
      const res = await api.addMember(orgId, inviteEmail, inviteRole);
      setMembers(res.members);
      setInviteEmail("");
      toast.success("Member added");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to add member");
    }
  }

  async function handleRoleChange(memberId: string, newRole: string) {
    try {
      const res = await api.updateMemberRole(orgId, memberId, newRole);
      setMembers(res.members);
      toast.success("Role updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update role");
    }
  }

  async function handleRemove(memberId: string) {
    if (!confirm("Remove this member?")) return;
    try {
      await api.removeMember(orgId, memberId);
      setMembers((prev) => prev.filter((m) => m.id !== memberId));
      toast.success("Member removed");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to remove member");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-text-muted">
        <Spinner size={20} />
        <span className="text-sm">Loading…</span>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold text-text">Members</h1>

      <form onSubmit={handleInvite} className="mb-6 flex flex-col gap-2 sm:flex-row">
        <Input
          type="email"
          placeholder="Email address"
          aria-label="Invite email address"
          value={inviteEmail}
          onChange={(e) => setInviteEmail(e.target.value)}
          className="sm:flex-1"
        />
        <Select
          aria-label="Invite role"
          value={inviteRole}
          onChange={(e) => setInviteRole(e.target.value)}
          className="sm:w-40"
        >
          {ROLES.filter((r) => r !== "owner").map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </Select>
        <Button type="submit">Add</Button>
      </form>

      <div className="overflow-x-auto rounded-lg border border-border bg-surface shadow-sm">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-text-secondary">
              <th className="px-3 py-2 font-medium">Email</th>
              <th className="px-3 py-2 font-medium">Role</th>
              <th className="px-3 py-2 font-medium">
                <span className="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {members.map((m) => (
              <tr key={m.id} className="border-b border-border last:border-0 text-text">
                <td className="px-3 py-2">{m.email}</td>
                <td className="px-3 py-2">
                  {m.role === "owner" ? (
                    <span className="text-text-secondary">owner</span>
                  ) : (
                    <Select
                      aria-label={`Role for ${m.email}`}
                      value={m.role}
                      onChange={(e) => handleRoleChange(m.id, e.target.value)}
                      className="w-32"
                    >
                      {ROLES.filter((r) => r !== "owner").map((r) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))}
                    </Select>
                  )}
                </td>
                <td className="px-3 py-2 text-right">
                  {m.role !== "owner" && m.user_id !== user?.id && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-error"
                      aria-label={`Remove ${m.email}`}
                      onClick={() => handleRemove(m.id)}
                    >
                      Remove
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
