"use client";

import { useParams } from "next/navigation";
import { SignupsView } from "@/components/org/signups-view";

export default function OrgSignupsPage() {
  const params = useParams<{ orgId: string; projectId: string; listId: string }>();
  const { orgId, projectId, listId } = params;
  return (
    <div style={{ maxWidth: 960, margin: "2rem auto", padding: "0 1.25rem" }}>
      <SignupsView
        listId={listId}
        backHref={`/app/${orgId}/services/${projectId}`}
        backLabel="Back to site lists"
      />
    </div>
  );
}
