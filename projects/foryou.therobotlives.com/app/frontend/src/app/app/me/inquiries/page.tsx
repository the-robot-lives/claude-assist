"use client";

import { AuthGate } from "@/components/preference-center/AuthGate";
import { InquiriesView } from "@/components/preference-center/InquiriesView";

// Full inquiries list + privacy (SCR-16), account-scoped.
export default function MyInquiriesPage() {
  return (
    <AuthGate next="/app/me/inquiries">
      <InquiriesView />
    </AuthGate>
  );
}
