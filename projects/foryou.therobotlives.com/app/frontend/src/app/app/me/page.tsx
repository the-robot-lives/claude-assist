"use client";

import { AuthGate } from "@/components/preference-center/AuthGate";
import { PreferenceCenter } from "@/components/preference-center/PreferenceCenter";

// Account-scoped preference center (sibling of /app/[orgId]; no org required — D12).
export default function MyPreferencesPage() {
  return (
    <AuthGate next="/app/me">
      <PreferenceCenter />
    </AuthGate>
  );
}
