// Reviews console descriptor — tobornalp's code/content-review domain. A review
// is opened over an artifact + revision and finalized (frozen) via completeReview,
// so the substrate is list/read-only: no edit form / update api. The detail page
// (app/[orgId]/reviews/[id]) owns the complete flow + verdict/summary entry.
//
// REST gate (tobornalp api.ts): listReviews / getReview exist. listReviews
// consumes { project_id, artifact_id, status } — the `status` facet key mirrors
// that param. BE statuses (schema/review.ex): open | in_progress | completed;
// verdicts: approved | changes_requested | rejected. Search is client-side only
// (listReviews has no search param); the facet is single-select for the same
// URLSearchParams array-serialization reason as artifacts.
import { api, type Review, type ReviewInput } from "@/lib/api";
import type { ConsoleDescriptor } from "../types";

export const REVIEW_STATUS_OPTIONS = [
  { value: "open", label: "Open" },
  { value: "in_progress", label: "In progress" },
  { value: "completed", label: "Completed" },
];

export const REVIEW_VERDICT_OPTIONS = [
  { value: "approved", label: "Approved" },
  { value: "changes_requested", label: "Changes requested" },
  { value: "rejected", label: "Rejected" },
];

export const reviewsDescriptor: ConsoleDescriptor<Review, ReviewInput> = {
  domain: "reviews",
  labels: { singular: "Review", plural: "Reviews" },
  route: "/app/:org/reviews",
  columns: [
    {
      key: "title",
      label: "Title",
      primary: true,
      sortable: true,
      width: "34%",
      render: (r) => r.title ?? "Untitled",
    },
    { key: "status", label: "Status", sortable: true, render: "statusChip" },
    { key: "reviewer_persona", label: "Reviewer", sortable: true, render: (r) => r.reviewer_persona ?? "—" },
    { key: "verdict", label: "Verdict", render: (r) => r.verdict ?? "—" },
    { key: "updated_at", label: "Updated", sortable: true, align: "right", render: "relativeDate" },
  ],
  filters: [
    { key: "search", label: "Search", type: "search" },
    { key: "status", label: "Status", type: "facet", options: REVIEW_STATUS_OPTIONS },
  ],
  detail: {
    sections: [
      {
        title: "Overview",
        fields: [
          { key: "title", label: "Title", render: (r) => r.title ?? "Untitled" },
          { key: "status", label: "Status", render: "statusChip" },
          { key: "reviewer_persona", label: "Reviewer", render: (r) => r.reviewer_persona ?? "—" },
          { key: "verdict", label: "Verdict", render: (r) => r.verdict ?? "—" },
          { key: "artifact_id", label: "Artifact", render: (r) => r.artifact_id ?? "—" },
          { key: "revision_id", label: "Revision", render: (r) => r.revision_id ?? "—" },
          { key: "inserted_at", label: "Created", render: "relativeDate" },
          { key: "updated_at", label: "Updated", render: "relativeDate" },
        ],
      },
      {
        title: "Summary",
        fields: [{ key: "summary", label: "Summary", span: true, render: (r) => r.summary ?? "—" }],
      },
    ],
  },
  // NOTE: reviews are finalized via completeReview (frozen), so this edit block
  // is nominal — no api.update is wired here, so EditForm never renders. The
  // detail page owns the complete/verdict flow. Present to satisfy the contract.
  edit: {
    sections: [
      {
        title: "Review",
        fields: [
          { key: "title", label: "Title", type: "text" },
          { key: "reviewer_persona", label: "Reviewer", type: "text" },
        ],
      },
    ],
  },
  // Reviews are completed (frozen) via completeReview, not a generic update — no
  // descriptor edit form. The detail page owns the complete/verdict flow.
  actions: { rowActions: ["view"] },
  api: {
    list: (orgId, opts) =>
      api
        .listReviews(
          orgId,
          opts as { project_id?: string; artifact_id?: string; status?: string | string[] },
        )
        .then((r) => r.reviews),
    // getReview returns { review, comments, overlays }; unwrap to the review.
    get: (orgId, id) => api.getReview(orgId, id).then((r) => r.review),
  },
};
