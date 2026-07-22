"use client";

import {
  createContext,
  useCallback,
  useContext,
  useRef,
  useState,
  type ReactNode,
} from "react";
import styles from "./preference-center.module.css";

type Announce = (message: string) => void;

const AnnouncerContext = createContext<Announce>(() => {});

/**
 * Provides an `aria-live="polite"` region so state changes (unsubscribe,
 * preference save, pause/resume) are announced to assistive tech (FR-012).
 * Toggling the message via a nonce forces re-announcement of repeats.
 */
export function AnnouncerProvider({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState("");
  const nonce = useRef(0);

  const announce = useCallback<Announce>((msg) => {
    nonce.current += 1;
    // Clear then set on the next tick so identical consecutive messages
    // still trigger a DOM change (and therefore an announcement).
    setMessage("");
    const n = nonce.current;
    requestAnimationFrame(() => {
      if (n === nonce.current) setMessage(msg);
    });
  }, []);

  return (
    <AnnouncerContext.Provider value={announce}>
      {children}
      <div
        className={styles.srOnly}
        role="status"
        aria-live="polite"
        aria-atomic="true"
      >
        {message}
      </div>
    </AnnouncerContext.Provider>
  );
}

export function useAnnounce(): Announce {
  return useContext(AnnouncerContext);
}
