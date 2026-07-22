"use client";

import type { SignupView } from "./api";
import { groupByService } from "./prefs";
import { SubscriptionRow, type RowHandlers } from "./SubscriptionRow";
import { EmptyState } from "./EmptyState";
import styles from "./preference-center.module.css";

export function SubscriptionList({
  signups,
  handlers,
  busyId,
}: {
  signups: SignupView[];
  handlers: RowHandlers;
  busyId: string | null;
}) {
  if (signups.length === 0) {
    return (
      <EmptyState title="No subscriptions yet">
        When you sign up for a newsletter or list on any DeRobot site, it will
        appear here so you can manage it in one place.
      </EmptyState>
    );
  }

  const groups = groupByService(signups);

  return (
    <div>
      {groups.map((group) => (
        <section key={group.key} className={styles.group} aria-label={group.name}>
          <div className={styles.groupHeader}>
            <span className={styles.groupTitle}>{group.name}</span>
            <span className={styles.groupCount}>
              {group.signups.length}{" "}
              {group.signups.length === 1 ? "subscription" : "subscriptions"}
            </span>
          </div>
          <div>
            {group.signups.map((s) => (
              <SubscriptionRow
                key={s.id}
                signup={s}
                handlers={handlers}
                busy={busyId === s.id}
              />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
