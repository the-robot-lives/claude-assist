"use client";

import { createContext, useContext } from "react";

const SectionIdContext = createContext<string | null>(null);

export const SectionIdProvider = SectionIdContext.Provider;

// ⟦𓆮𓃲𓄀𓇧⟧ useSectionId :: auto-generated pointer for public function useSectionId
export function useSectionId(): string | null {
  return useContext(SectionIdContext);
}
