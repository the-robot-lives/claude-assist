"use client";

import { useCallback, useEffect, useRef, useState, type DependencyList } from "react";

// Thin data-fetching hook over the `api` layer in src/lib/api.ts. It does NOT re-implement
// token/refresh — pass a fetcher that calls `api.*` (which routes through `request<T>`).
//
// Refetch-on-focus is a stale-view stopgap: when the tab regains focus we silently re-fetch
// (without flipping `loading`, so the UI doesn't flash a spinner). `mutate()` is the manual,
// loading-visible refetch for post-write refresh.

export interface UseApiResult<T> {
  data: T | null;
  error: Error | null;
  loading: boolean;
  mutate: () => void;
}

function toError(e: unknown): Error {
  return e instanceof Error ? e : new Error(String(e));
}

export function useApi<T>(fetcher: () => Promise<T>, deps: DependencyList = []): UseApiResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  // Keep the latest fetcher without making it a dependency of the fetch effect —
  // callers typically pass a fresh closure each render; `deps` controls when to refetch.
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;
  const mountedRef = useRef(false);

  const run = useCallback((silent: boolean) => {
    if (!silent) setLoading(true);
    setError(null);
    return fetcherRef
      .current()
      .then((res) => {
        if (mountedRef.current) setData(res);
      })
      .catch((e) => {
        if (mountedRef.current) setError(toError(e));
      })
      .finally(() => {
        if (mountedRef.current) setLoading(false);
      });
  }, []);

  const mutate = useCallback(() => {
    run(false);
  }, [run]);

  useEffect(() => {
    mountedRef.current = true;
    run(false);
    return () => {
      mountedRef.current = false;
    };
    // Refetch when caller-provided deps change; `run` is stable.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    const onFocus = () => run(true);
    window.addEventListener("focus", onFocus);
    return () => window.removeEventListener("focus", onFocus);
  }, [run]);

  return { data, error, loading, mutate };
}

// ── useMutation ───────────────────────────────────────────────────────────────
// Wraps a write. `optimistic` runs before the request (mutate local state); `revert`
// runs if it rejects (undo). `trigger` resolves with the result or rejects — callers
// can await it and surface a toast.

export interface UseMutationOptions<V> {
  optimistic?: (v: V) => void;
  revert?: (e: Error) => void;
}

export interface UseMutationResult<T, V> {
  trigger: (v: V) => Promise<T>;
  loading: boolean;
  error: Error | null;
}

export function useMutation<T, V = void>(
  mutator: (v: V) => Promise<T>,
  opts: UseMutationOptions<V> = {},
): UseMutationResult<T, V> {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const mutatorRef = useRef(mutator);
  mutatorRef.current = mutator;
  const optsRef = useRef(opts);
  optsRef.current = opts;
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const trigger = useCallback(async (v: V): Promise<T> => {
    if (mountedRef.current) {
      setLoading(true);
      setError(null);
    }
    optsRef.current.optimistic?.(v);
    try {
      return await mutatorRef.current(v);
    } catch (e) {
      const err = toError(e);
      if (mountedRef.current) setError(err);
      optsRef.current.revert?.(err);
      throw err;
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  return { trigger, loading, error };
}
