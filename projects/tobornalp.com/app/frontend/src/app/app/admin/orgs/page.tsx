"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Btn, Spinner, Panel, PanelHeader } from "@/components/ui";

interface AdminOrg {
  id: string;
  slug: string;
  name: string;
  created_at: string;
}

export default function AdminOrgsPage() {
  const [orgs, setOrgs] = useState<AdminOrg[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .adminListOrganizations(page)
      .then((res) => {
        setOrgs(res.organizations);
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
        <PanelHeader title="organizations" right={`${total} total`} />
        <div className="overflow-x-auto">
          <table className="w-full text-[12px]">
            <thead>
              <tr>
                <th className="border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  name
                </th>
                <th className="border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  slug
                </th>
                <th className="border-b border-line2 bg-panel2 px-4 py-2 text-left text-[10px] font-bold uppercase tracking-[0.12em] text-faint">
                  created
                </th>
              </tr>
            </thead>
            <tbody>
              {orgs.map((o) => (
                <tr key={o.id} className="border-b border-line last:border-0 hover:bg-sel">
                  <td className="px-4 py-2 font-bold text-ink">{o.name}</td>
                  <td className="px-4 py-2 text-mut">{o.slug}</td>
                  <td className="px-4 py-2 text-faint">{new Date(o.created_at).toLocaleDateString()}</td>
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
        <Btn variant="default" disabled={orgs.length < 50} onClick={() => setPage(page + 1)}>
          next
        </Btn>
      </div>
    </div>
  );
}
