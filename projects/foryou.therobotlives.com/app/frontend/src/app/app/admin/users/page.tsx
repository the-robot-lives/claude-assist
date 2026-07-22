"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";

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
    api.adminListUsers(page).then((res) => {
      setUsers(res.users);
      setTotal(res.total);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [page]);

  if (loading) return <p className="sg-admin-loading">Loading...</p>;

  return (
    <div>
      <h1 className="sg-section-heading">Users ({total})</h1>
      <table className="sg-table">
        <thead>
          <tr>
            <th>Email</th>
            <th>Username</th>
            <th>Status</th>
            <th>Verified</th>
            <th>Admin</th>
          </tr>
        </thead>
        <tbody>
          {users.map((u) => (
            <tr key={u.id}>
              <td>{u.email}</td>
              <td>{u.user_name}</td>
              <td>{u.status}</td>
              <td>{u.verified ? "Yes" : "No"}</td>
              <td>{u.admin ? "Yes" : "No"}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="sg-pagination">
        <button className="sg-btn sg-btn--outline sg-btn--sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>Prev</button>
        <span className="sg-pagination__status">Page {page}</span>
        <button className="sg-btn sg-btn--outline sg-btn--sm" disabled={users.length < 50} onClick={() => setPage(page + 1)}>Next</button>
      </div>
    </div>
  );
}
