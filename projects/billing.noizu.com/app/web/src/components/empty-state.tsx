import Link from "next/link";
import type { Route } from "next";

type EmptyStateProps = {
  eyebrow?: string;
  title: string;
  body: string;
  actionHref?: Route;
  actionLabel?: string;
};

export function EmptyState({ eyebrow, title, body, actionHref, actionLabel }: EmptyStateProps) {
  return (
    <div className="empty-state">
      {eyebrow ? <p className="eyebrow">{eyebrow}</p> : null}
      <h3>{title}</h3>
      <p>{body}</p>
      {actionHref && actionLabel ? (
        <Link className="button primary" href={actionHref}>
          {actionLabel}
        </Link>
      ) : null}
    </div>
  );
}
