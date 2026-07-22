"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Button, Spinner, StatusBadge } from "@/components/ui";

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
      <div className="flex items-center justify-center gap-2 p-16 text-text-muted">
        <Spinner size={20} />
        <span className="text-sm">Loading…</span>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <h1 className="mb-4 text-2xl font-bold text-text">
        Users <span className="text-text-muted">({total})</span>
      </h1>

      <div className="overflow-x-auto rounded-lg border border-border bg-surface shadow-sm">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-text-secondary">
              <th className="px-3 py-2 font-medium">Email</th>
              <th className="px-3 py-2 font-medium">Username</th>
              <th className="px-3 py-2 font-medium">Status</th>
              <th className="px-3 py-2 font-medium">Verified</th>
              <th className="px-3 py-2 font-medium">Admin</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0 text-text">
                <td className="px-3 py-2">{u.email}</td>
                <td className="px-3 py-2">{u.user_name}</td>
                <td className="px-3 py-2">
                  <StatusBadge status={u.status} />
                </td>
                <td className="px-3 py-2 text-text-secondary">{u.verified ? "Yes" : "No"}</td>
                <td className="px-3 py-2 text-text-secondary">{u.admin ? "Yes" : "No"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-4 flex items-center gap-3">
        <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>
          Prev
        </Button>
        <span className="text-sm text-text-muted">Page {page}</span>
        <Button variant="outline" size="sm" disabled={users.length < 50} onClick={() => setPage(page + 1)}>
          Next
        </Button>
      </div>
    </div>
  );
}
