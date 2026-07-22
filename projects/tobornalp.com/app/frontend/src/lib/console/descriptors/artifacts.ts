// Artifacts console descriptor — tobornalp's versioned typed-content domain.
// List-only via the substrate: artifacts evolve through REVISIONS, not an
// in-place update, so there is no edit form / update api here. The detail page
// (app/[orgId]/artifacts/[id]) owns revision history + create-revision.
//
// REST gate (tobornalp api.ts): listArtifacts / getArtifact both exist.
// listArtifacts consumes { project_id, kind, search } — the `kind` facet key
// mirrors that snake_case param so DataTable passes it straight through. `kind`
// is single-select: listArtifacts accepts string | string[], but tobornalp's
// buildQuery uses URLSearchParams (no array serialization), so a single value
// is the safe path. Search stays client-side over the loaded page.
import { api, type Artifact, type ArtifactInput } from "@/lib/api";
import type { ConsoleDescriptor } from "../types";

export const ARTIFACT_KIND_OPTIONS = [
  { value: "code", label: "Code" },
  { value: "document", label: "Document" },
  { value: "image", label: "Image" },
  { value: "wiki", label: "Wiki" },
  { value: "config", label: "Config" },
  { value: "binary", label: "Binary" },
];

export const artifactsDescriptor: ConsoleDescriptor<Artifact, ArtifactInput> = {
  domain: "artifacts",
  labels: { singular: "Artifact", plural: "Artifacts" },
  route: "/app/:org/artifacts",
  columns: [
    { key: "title", label: "Title", primary: true, sortable: true, width: "40%" },
    { key: "kind", label: "Kind", sortable: true },
    { key: "mime_type", label: "Type", render: (a) => a.mime_type ?? "—" },
    { key: "project_id", label: "Project", render: (a) => a.project_id ?? "—" },
    { key: "updated_at", label: "Updated", sortable: true, align: "right", render: "relativeDate" },
  ],
  filters: [
    { key: "search", label: "Search", type: "search" },
    { key: "kind", label: "Kind", type: "facet", options: ARTIFACT_KIND_OPTIONS },
  ],
  detail: {
    sections: [
      {
        title: "Overview",
        fields: [
          { key: "title", label: "Title" },
          { key: "kind", label: "Kind" },
          { key: "mime_type", label: "Type", render: (a) => a.mime_type ?? "—" },
          { key: "project_id", label: "Project", render: (a) => a.project_id ?? "—" },
          { key: "id", label: "ID" },
          { key: "inserted_at", label: "Created", render: "relativeDate" },
          { key: "updated_at", label: "Updated", render: "relativeDate" },
        ],
      },
    ],
  },
  // NOTE: artifacts evolve via revisions, so this edit block is nominal — no
  // api.update is wired (createArtifactRevision is the edit path), so EditForm
  // never renders. Present only to satisfy the ConsoleDescriptor contract.
  edit: {
    sections: [
      {
        title: "Artifact",
        fields: [
          { key: "title", label: "Title", type: "text", required: true },
          { key: "kind", label: "Kind", type: "select", options: ARTIFACT_KIND_OPTIONS },
          { key: "mime_type", label: "MIME type", type: "text" },
        ],
      },
    ],
  },
  // Artifacts are revised (createArtifactRevision), not updated in place — no
  // descriptor edit form. The detail page owns the revision flow.
  actions: { rowActions: ["view"] },
  api: {
    list: (orgId, opts) =>
      api
        .listArtifacts(
          orgId,
          opts as { project_id?: string; kind?: string | string[]; search?: string },
        )
        .then((r) => r.artifacts),
    // getArtifact returns ArtifactDetail (a subtype of Artifact — content +
    // revision pointer). Covariant under the descriptor's Promise<Artifact>.
    get: (orgId, id) => api.getArtifact(orgId, id).then((r) => r.artifact),
  },
};
