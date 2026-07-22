"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Sidebar } from "@/components/layout/sidebar";
import { TopBar } from "@/components/layout/top-bar";
import { StatusBar } from "@/components/layout/status-bar";
import { universesApi } from "@/lib/api";
import { toUiUniverse } from "@/lib/api/mappers";
import type { Universe } from "@/types/universe";

export default function UniverseLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { universeId } = useParams() as { universeId: string };
  const [universe, setUniverse] = useState<Universe | null>(null);

  useEffect(() => {
    let cancelled = false;
    universesApi
      .get(universeId)
      .then(({ universe: u }) => {
        if (!cancelled) setUniverse(toUiUniverse(u));
      })
      .catch(() => {
        if (!cancelled)
          setUniverse({
            id: universeId,
            name: universeId,
            genre: "",
            description: "",
            entryCount: 0,
            flagCount: 0,
            connectionCount: 0,
            updatedAt: new Date().toISOString(),
          });
      });
    return () => {
      cancelled = true;
    };
  }, [universeId]);

  const name = universe?.name ?? universeId;

  return (
    <div className="flex h-screen bg-page overflow-hidden">
      <Sidebar universeId={universeId} universeName={name} />

      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        <TopBar title={name} backHref="/app" backLabel="Universes" />

        <main className="flex-1 overflow-y-auto bg-page">{children}</main>

        <StatusBar
          entryCount={universe?.entryCount ?? 0}
          connectionCount={universe?.connectionCount ?? 0}
          flagCount={universe?.flagCount ?? 0}
          lastSync="live"
        />
      </div>
    </div>
  );
}
