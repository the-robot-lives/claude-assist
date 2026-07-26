"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";
import { useOrg } from "@/context/org";
import { CloudDocStore } from "./cloud-doc-store";
import { LocalDraftStore } from "./local-draft-store";
import type { DocStore } from "./doc-store";

/** Sticky project selection, so a reload reopens the workspace where it was. Phase 2
 * replaces this with real workspace/project switching in the browser dock. */
const projectKey = "trd:vnext:project-id";

export interface DocStoreBinding {
  store: DocStore;
  /** False until auth, org and project resolution have settled — the workspace waits so
   * it does not list local drafts and then immediately relist cloud documents. */
  ready: boolean;
  projectId: string | null;
  /** Set when a signed-in session could not be pointed at a project, so the workspace can
   * say why it fell back to browser-local storage. */
  fallbackReason: string | null;
}

/**
 * Resolves which `DocStore` this session should use.
 *
 * Signed in with a reachable project → `CloudDocStore`. Anything else — logged out, no
 * project, backend unreachable — → `LocalDraftStore`, so the workspace keeps working
 * exactly as the logged-out demo does.
 */
export function useDocStore(): DocStoreBinding {
  const { user, loading: authLoading } = useAuth();
  const { currentOrg, loading: orgLoading } = useOrg();
  const [projectId, setProjectId] = useState<string | null>(null);
  const [resolving, setResolving] = useState(false);
  const [fallbackReason, setFallbackReason] = useState<string | null>(null);
  const localStore = useRef(new LocalDraftStore());

  useEffect(() => {
    if (!user || !currentOrg) {
      setProjectId(null);
      setFallbackReason(null);
      return;
    }

    let cancelled = false;
    setResolving(true);
    api
      .listProjects(currentOrg.id)
      .then(({ projects }) => {
        if (cancelled) return;
        const remembered = window.localStorage.getItem(projectKey);
        const chosen = projects.find((project) => project.id === remembered) ?? projects[0];
        if (!chosen) {
          setProjectId(null);
          setFallbackReason(`${currentOrg.name} has no project to store models in`);
          return;
        }
        window.localStorage.setItem(projectKey, chosen.id);
        setProjectId(chosen.id);
        setFallbackReason(null);
      })
      .catch((error: unknown) => {
        if (cancelled) return;
        setProjectId(null);
        setFallbackReason(error instanceof Error ? error.message : "project lookup failed");
      })
      .finally(() => {
        if (!cancelled) setResolving(false);
      });

    return () => {
      cancelled = true;
    };
  }, [user, currentOrg]);

  const store = useMemo<DocStore>(
    () => (projectId ? new CloudDocStore(projectId) : localStore.current),
    [projectId],
  );

  return {
    store,
    ready: !authLoading && !orgLoading && !resolving,
    projectId,
    fallbackReason,
  };
}
