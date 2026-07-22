"use client";

import { useEffect } from "react";
import { initOtel } from "@/lib/otel";

// ⟦𓎽𓌅𓂟𓀦⟧ OtelProvider :: auto-generated pointer for public function OtelProvider
export function OtelProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    initOtel();
  }, []);

  return <>{children}</>;
}
