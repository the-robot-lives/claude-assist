"use client";

import { createContext, useContext, useState } from "react";

interface SemanticSelectionCtx {
  selected: string;
  setSelected: (name: string) => void;
}

const SemanticSelectionContext = createContext<SemanticSelectionCtx>({
  selected: "",
  setSelected: () => {},
});

// ⟦𓉌𓐘𓍍𓃔⟧ SemanticSelectionProvider :: auto-generated pointer for public function SemanticSelectionProvider
export function SemanticSelectionProvider({
  defaultSelected,
  children,
}: {
  defaultSelected: string;
  children: React.ReactNode;
}) {
  const [selected, setSelected] = useState(defaultSelected);
  return (
    <SemanticSelectionContext.Provider value={{ selected, setSelected }}>
      {children}
    </SemanticSelectionContext.Provider>
  );
}

// ⟦𓃌𓊉𓏹𓐀⟧ useSemanticSelection :: auto-generated pointer for public function useSemanticSelection
export function useSemanticSelection() {
  return useContext(SemanticSelectionContext);
}
