"use client";

import { useParams } from "next/navigation";
import { SignupsView } from "@/components/org/signups-view";

export default function AdminSignupsPage() {
  const params = useParams<{ projectId: string; listId: string }>();
  return (
    <SignupsView
      listId={params.listId}
      backHref={`/app/admin/services/${params.projectId}`}
      backLabel="Back to lists"
    />
  );
}
