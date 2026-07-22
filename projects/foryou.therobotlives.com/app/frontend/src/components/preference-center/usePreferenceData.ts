"use client";

import { useCallback, useEffect, useState } from "react";
import { pcApi, type InquiryView, type SignupView } from "./api";

interface SectionState<T> {
  data: T;
  loading: boolean;
  error: string | null;
}

/**
 * Loads `/me/signups` and `/me/inquiries` in parallel with independent state
 * so one section failing (5xx) still renders the other (FR-001 partial-load).
 */
export function usePreferenceData() {
  const [signups, setSignups] = useState<SectionState<SignupView[]>>({
    data: [],
    loading: true,
    error: null,
  });
  const [inquiries, setInquiries] = useState<SectionState<InquiryView[]>>({
    data: [],
    loading: true,
    error: null,
  });

  const loadSignups = useCallback(async () => {
    setSignups((s) => ({ ...s, loading: true, error: null }));
    try {
      const { signups } = await pcApi.getMySignups();
      setSignups({ data: signups ?? [], loading: false, error: null });
    } catch (e) {
      setSignups((s) => ({
        ...s,
        loading: false,
        error: e instanceof Error ? e.message : "Could not load subscriptions.",
      }));
    }
  }, []);

  const loadInquiries = useCallback(async () => {
    setInquiries((s) => ({ ...s, loading: true, error: null }));
    try {
      const { inquiries } = await pcApi.getMyInquiries();
      setInquiries({ data: inquiries ?? [], loading: false, error: null });
    } catch (e) {
      setInquiries((s) => ({
        ...s,
        loading: false,
        error: e instanceof Error ? e.message : "Could not load inquiries.",
      }));
    }
  }, []);

  useEffect(() => {
    // Parallel, independent.
    loadSignups();
    loadInquiries();
  }, [loadSignups, loadInquiries]);

  /** Replace one signup in place (optimistic + after-mutation reconciliation). */
  const patchSignup = useCallback(
    (id: string, next: Partial<SignupView> | SignupView) => {
      setSignups((s) => ({
        ...s,
        data: s.data.map((row) =>
          row.id === id ? { ...row, ...next } : row,
        ),
      }));
    },
    [],
  );

  const removeSignup = useCallback((id: string) => {
    setSignups((s) => ({ ...s, data: s.data.filter((r) => r.id !== id) }));
  }, []);

  return {
    signups,
    inquiries,
    reloadSignups: loadSignups,
    reloadInquiries: loadInquiries,
    patchSignup,
    removeSignup,
  };
}
