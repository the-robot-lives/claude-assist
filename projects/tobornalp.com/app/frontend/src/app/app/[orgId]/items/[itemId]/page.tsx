"use client";

// Item detail page — rebased onto the descriptor-driven console substrate.
// Header + core fields (Overview / Description / Meta) come from the shared
// items descriptor via ConsoleDetailPage/DetailView (left untouched), with
// inline edit via ?edit=1. Below that, three custom sections are rendered
// directly here (NOT via the descriptor) so the shared descriptor stays owned
// by Agent A: Comments (threaded, optimistic), Activity (event timeline), and
// Links (blocks / blocked_by / relates_to / duplicates).
//
// Org resolution follows tobornalp's convention: currentOrg?.id (UUID) is what
// the UUID-keyed api expects and what the /app/[orgId]/... routes carry.
import { useMemo } from "react";
import { useParams, useSearchParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { ConsoleDetailPage } from "@/components/console/ConsoleDetailPage";
import { itemsDescriptor } from "@/lib/console/descriptors/items";
import { CommentsSection } from "@/components/items/comments";
import { ActivitySection } from "@/components/items/activity";
import { LinksSection } from "@/components/items/links";

export default function ItemDetailPage() {
  const params = useParams<{ orgId: string; itemId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const searchParams = useSearchParams();
  const initialMode = searchParams.get("edit") === "1" ? "edit" : "view";

  const ctx = useMemo(() => ({ orgId: orgId ?? "" }), [orgId]);

  if (orgLoading || !orgId) {
    return <p className="px-4 py-6 font-mono text-sm text-mut">loading…</p>;
  }

  return (
    <div className="app-content max-w-3xl">
      <ConsoleDetailPage
        ctx={ctx}
        id={params.itemId}
        descriptor={itemsDescriptor}
        initialMode={initialMode}
      />

      {/* Custom sections sit outside the descriptor's <article>, in the same
          app-content column so they line up. Hidden in edit mode (deep-link
          ?edit=1) to keep the edit form the focus. */}
      {initialMode === "view" && (
        <div className="space-y-4">
          <CommentsSection orgId={orgId} itemId={params.itemId} />
          <ActivitySection orgId={orgId} itemId={params.itemId} />
          <LinksSection orgId={orgId} itemId={params.itemId} />
        </div>
      )}
    </div>
  );
}
