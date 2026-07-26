"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";
import { toast } from "sonner";
import { Input, Select, Spinner, Panel, PanelHeader, Btn, Avatar, Chip } from "@/components/ui";

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
      toast.success("member added");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to add member");
    }
  }

  async function handleRoleChange(memberId: string, newRole: string) {
    try {
      const res = await api.updateMemberRole(orgId, memberId, newRole);
      setMembers(res.members);
      toast.success("role updated");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to update role");
    }
  }

  async function handleRemove(memberId: string) {
    if (!confirm("remove this member?")) return;
    try {
      await api.removeMember(orgId, memberId);
      setMembers((prev) => prev.filter((m) => m.id !== memberId));
      toast.success("member removed");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to remove member");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-faint">
        <Spinner size={20} />
        <span className="text-[12px]">loading…</span>
      </div>
    );
  }

  return (
    <div className="app-content">
      <Panel>
        <PanelHeader title="invite member" sub="add a teammate to this org" />
        <form onSubmit={handleInvite} className="flex flex-col gap-2.5 p-4 sm:flex-row">
          <Input
            type="email"
            placeholder="email address"
            aria-label="invite email address"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            className="rounded-card border-line2 bg-ground sm:flex-1"
          />
          <Select
            aria-label="invite role"
            value={inviteRole}
            onChange={(e) => setInviteRole(e.target.value)}
            className="rounded-card border-line2 bg-ground sm:w-40"
          >
            {ROLES.filter((r) => r !== "owner").map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </Select>
          <Btn type="submit" variant="primary">
            invite
          </Btn>
        </form>
      </Panel>

      <Panel>
        <PanelHeader title="roster" sub="org members — assignable, reviewable" right={`${members.length} total`} />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-[12px]">
            <thead>
              <tr>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  member
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  role
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  <span className="sr-only">actions</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {members.map((m) => (
                <tr key={m.id} className="border-b border-line last:border-0 hover:bg-sel">
                  <td className="px-4 py-2">
                    <span className="flex items-center gap-2.5 font-bold text-ink">
                      <Avatar name={m.user_name || m.email} />
                      {m.email}
                    </span>
                  </td>
                  <td className="px-4 py-2">
                    {m.role === "owner" ? (
                      <Chip variant="scope">owner</Chip>
                    ) : (
                      <Select
                        aria-label={`role for ${m.email}`}
                        value={m.role}
                        onChange={(e) => handleRoleChange(m.id, e.target.value)}
                        className="w-32 rounded-card border-line2 bg-ground"
                      >
                        {ROLES.filter((r) => r !== "owner").map((r) => (
                          <option key={r} value={r}>
                            {r}
                          </option>
                        ))}
                      </Select>
                    )}
                  </td>
                  <td className="px-4 py-2 text-right">
                    {m.role !== "owner" && m.user_id !== user?.id && (
                      <Btn
                        variant="default"
                        className="border-err/40 text-err hover:border-err hover:text-err"
                        aria-label={`remove ${m.email}`}
                        onClick={() => handleRemove(m.id)}
                      >
                        remove
                      </Btn>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>
    </div>
  );
}
