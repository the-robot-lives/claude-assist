"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Btn, Spinner, StatusBadge, Panel, PanelHeader, StatusTag } from "@/components/ui";

interface AdminUser {
  id: string;
  email: string;
  user_name: string;
  status: string;
  verified: boolean;
  admin: boolean;
  created_at: string;
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .adminListUsers(page)
      .then((res) => {
        setUsers(res.users);
        setTotal(res.total);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [page]);

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-faint">
        <Spinner size={20} />
        <span className="text-[12px]">loading…</span>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <Panel>
        <PanelHeader title="users" right={`${total} total`} />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-[12px]">
            <thead>
              <tr>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  email
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  username
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  status
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  verified
                </th>
                <th className="whitespace-nowrap border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  admin
                </th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} className="border-b border-line last:border-0 hover:bg-sel">
                  <td className="px-4 py-2 font-bold text-ink">{u.email}</td>
                  <td className="px-4 py-2 text-mut">{u.user_name}</td>
                  <td className="px-4 py-2">
                    <StatusBadge status={u.status} />
                  </td>
                  <td className="px-4 py-2">{u.verified ? <StatusTag tone="ok" /> : <span className="text-faint">—</span>}</td>
                  <td className="px-4 py-2">{u.admin ? <StatusTag tone="ok" /> : <span className="text-faint">—</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>

      <div className="mt-4 flex items-center gap-3">
        <Btn variant="default" disabled={page <= 1} onClick={() => setPage(page - 1)}>
          prev
        </Btn>
        <span className="text-[12px] text-faint">page {page}</span>
        <Btn variant="default" disabled={users.length < 50} onClick={() => setPage(page + 1)}>
          next
        </Btn>
      </div>
    </div>
  );
}
