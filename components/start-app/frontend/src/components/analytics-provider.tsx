"use client";

import { Suspense } from "react";
import { usePageView } from "@/lib/analytics/use-analytics";

function AnalyticsPageView() {
  usePageView();
  return null;
}

// ⟦𓊲𓃿𓇜𓎑⟧ AnalyticsProvider :: auto-generated pointer for public function AnalyticsProvider
export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Suspense fallback={null}>
        <AnalyticsPageView />
      </Suspense>
      {children}
    </>
  );
}
