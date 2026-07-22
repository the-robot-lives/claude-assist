import { createContext, useContext, type Dispatch, type SetStateAction } from "react";

export type FocusZone = "header" | "sidebar" | "controls" | "content";

export interface FocusContextValue {
  focusZone: FocusZone;
  setFocusZone?: Dispatch<SetStateAction<FocusZone>>;
  setTrapContentTab?: Dispatch<SetStateAction<boolean>>;
}

const Context = createContext<FocusContextValue>({ focusZone: "content" });

export const FocusProvider = Context.Provider;

export function useFocusZone(): FocusZone {
  return useContext(Context).focusZone;
}

export function useFocusContext(): FocusContextValue {
  return useContext(Context);
}
