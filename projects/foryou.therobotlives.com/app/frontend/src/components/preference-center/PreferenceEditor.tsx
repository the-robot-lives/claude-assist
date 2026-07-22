"use client";

import { useMemo, useState } from "react";
import {
  CHANNEL_KEYS,
  pcApi,
  PcApiError,
  type ChannelKey,
  type ContactPrefs,
  type Frequency,
  type QuietPeriod,
  type SignupView,
} from "./api";
import {
  availableChannels,
  CHANNEL_LABELS,
  DELIVERABLE_CHANNELS,
  effectivePrefs,
  FREQUENCIES,
  FREQUENCY_LABELS,
  hasOverride,
} from "./prefs";
import { Modal } from "./Modal";
import { InlineAlert } from "./InlineAlert";
import { useAnnounce } from "./Announcer";
import styles from "./preference-center.module.css";

const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"] as const;

function guessTimezone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
}

/**
 * Per-subscription contact-preference editor (SCR-15 / FR-005). Seeds from the
 * effective prefs (override-or-default), gates channels to the list's
 * available set, and PATCHes on save. Non-email channels are selectable but
 * flagged "delivery coming soon" (stored, not sent — post-M5).
 */
export function PreferenceEditor({
  signup,
  onClose,
  onSaved,
}: {
  signup: SignupView;
  onClose: () => void;
  onSaved: (updated: SignupView) => void;
}) {
  const announce = useAnnounce();
  const eff = useMemo(() => effectivePrefs(signup), [signup]);
  const offered = useMemo(() => availableChannels(signup), [signup]);

  const [frequency, setFrequency] = useState<Frequency>(eff.frequency);
  const [channels, setChannels] = useState<Record<ChannelKey, boolean>>({
    ...eff.channels,
  });
  const [quietPeriods, setQuietPeriods] = useState<QuietPeriod[]>(
    eff.quiet_periods.map((q) => ({ ...q })),
  );
  const [pauseUntil, setPauseUntil] = useState<string>(
    signup.pause_until ? signup.pause_until.slice(0, 10) : "",
  );

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const overridden = hasOverride(signup);

  function toggleChannel(key: ChannelKey) {
    if (!offered.includes(key)) return; // not selectable
    setChannels((c) => ({ ...c, [key]: !c[key] }));
  }

  function addQuietPeriod() {
    setQuietPeriods((qp) => [
      ...qp,
      { start: "22:00", end: "07:00", timezone: guessTimezone(), days: [] },
    ]);
  }

  function updateQuietPeriod(i: number, patch: Partial<QuietPeriod>) {
    setQuietPeriods((qp) =>
      qp.map((q, idx) => (idx === i ? { ...q, ...patch } : q)),
    );
  }

  function removeQuietPeriod(i: number) {
    setQuietPeriods((qp) => qp.filter((_, idx) => idx !== i));
  }

  function toggleDay(i: number, day: string) {
    setQuietPeriods((qp) =>
      qp.map((q, idx) => {
        if (idx !== i) return q;
        const days = new Set(q.days ?? []);
        if (days.has(day)) days.delete(day);
        else days.add(day);
        return { ...q, days: Array.from(days) };
      }),
    );
  }

  function validate(): string | null {
    if (pauseUntil) {
      const t = Date.parse(pauseUntil);
      if (!Number.isFinite(t)) return "Pause date is invalid.";
      // Compare against end of the chosen day to allow "today".
      if (t + 24 * 60 * 60 * 1000 < Date.now())
        return "Pause date cannot be in the past.";
    }
    for (const q of quietPeriods) {
      if (!q.start || !q.end) return "Quiet periods need a start and end time.";
    }
    return null;
  }

  async function save() {
    const problem = validate();
    if (problem) {
      setError(problem);
      announce(problem);
      return;
    }
    setBusy(true);
    setError(null);

    // Force non-offered channels false; ensure every offered channel present.
    const outChannels: Partial<Record<ChannelKey, boolean>> = {};
    for (const k of CHANNEL_KEYS) {
      outChannels[k] = offered.includes(k) ? !!channels[k] : false;
    }
    const contact_prefs: ContactPrefs = {
      frequency,
      channels: outChannels,
      quiet_periods: quietPeriods.map((q) => ({
        ...q,
        timezone: q.timezone || guessTimezone(),
      })),
    };
    const body = {
      contact_prefs,
      pause_until: pauseUntil ? new Date(pauseUntil).toISOString() : null,
    };

    try {
      const { signup: updated } = await pcApi.updateMySignupPrefs(
        signup.id,
        body,
      );
      onSaved(updated ?? { ...signup, contact_prefs, pause_until: body.pause_until });
      announce("Preferences saved.");
      onClose();
    } catch (e) {
      const msg = describeError(e);
      setError(msg);
      announce(msg);
      setBusy(false);
    }
  }

  async function resetToDefault() {
    setBusy(true);
    setError(null);
    try {
      const { signup: updated } = await pcApi.updateMySignupPrefs(signup.id, {
        reset_to_default: true,
      });
      onSaved(updated ?? { ...signup, contact_prefs: {} });
      announce("Preferences reset to the list default.");
      onClose();
    } catch (e) {
      const msg = describeError(e);
      setError(msg);
      announce(msg);
      setBusy(false);
    }
  }

  const listName = signup.list?.name ?? "this list";

  return (
    <Modal
      title={
        <>
          Contact preferences
          <span className={styles.muted} style={{ fontWeight: 400 }}>
            {" "}
            · {listName}
          </span>
        </>
      }
      onClose={busy ? () => {} : onClose}
      footer={
        <>
          <button
            type="button"
            className="sg-btn sg-btn--outline sg-btn--sm"
            onClick={resetToDefault}
            disabled={busy || !overridden}
            title={
              overridden
                ? "Clear your overrides and inherit the list default"
                : "Already using the list default"
            }
          >
            Reset to default
          </button>
          <span style={{ flex: 1 }} />
          <button
            type="button"
            className="sg-btn sg-btn--outline sg-btn--sm"
            onClick={onClose}
            disabled={busy}
          >
            Cancel
          </button>
          <button
            type="button"
            className="sg-btn sg-btn--black sg-btn--sm"
            onClick={save}
            disabled={busy}
          >
            {busy && <span className={styles.spinner} aria-hidden="true" />}{" "}
            {busy ? "Saving…" : "Save preferences"}
          </button>
        </>
      }
    >
      <p className={styles.muted} style={{ marginTop: 0, fontSize: "0.85rem" }}>
        {overridden ? (
          <>
            You have custom preferences for this subscription.{" "}
            <span className={styles.overrideTag}>Overridden</span>
          </>
        ) : (
          <>
            Using the list default.{" "}
            <span className={styles.inheritTag}>Inherited</span>
          </>
        )}
      </p>

      {/* Frequency ------------------------------------------------------- */}
      <fieldset className={styles.fieldset}>
        <legend className={styles.legend}>Frequency</legend>
        <label className={styles.inlineLabel} htmlFor="pc-frequency">
          How often should we contact you?
        </label>
        <select
          id="pc-frequency"
          className={styles.rowInput}
          value={frequency}
          onChange={(e) => setFrequency(e.target.value as Frequency)}
          disabled={busy}
        >
          {FREQUENCIES.map((f) => (
            <option key={f} value={f}>
              {FREQUENCY_LABELS[f]}
            </option>
          ))}
        </select>
      </fieldset>

      {/* Channels -------------------------------------------------------- */}
      <fieldset className={styles.fieldset}>
        <legend className={styles.legend}>Channels</legend>
        {CHANNEL_KEYS.filter((k) => offered.includes(k)).map((k) => {
          const deferred = !DELIVERABLE_CHANNELS.includes(k);
          return (
            <div key={k} className={styles.channelRow}>
              <input
                type="checkbox"
                id={`pc-ch-${k}`}
                checked={!!channels[k]}
                onChange={() => toggleChannel(k)}
                disabled={busy}
              />
              <label htmlFor={`pc-ch-${k}`}>{CHANNEL_LABELS[k]}</label>
              {deferred && (
                <span className={styles.channelSoon}>
                  stored · delivery coming soon
                </span>
              )}
            </div>
          );
        })}
        {offered.length <= 1 && (
          <InlineAlert variant="info">
            Only email delivery is available right now. Other channels will
            appear here as they launch.
          </InlineAlert>
        )}
      </fieldset>

      {/* Quiet periods --------------------------------------------------- */}
      <fieldset className={styles.fieldset}>
        <legend className={styles.legend}>Quiet periods</legend>
        {quietPeriods.length === 0 && (
          <p className={styles.muted} style={{ fontSize: "0.85rem", margin: "0 0 0.5rem" }}>
            No quiet periods. Add one to avoid contact during certain hours.
          </p>
        )}
        {quietPeriods.map((q, i) => (
          <div key={i} className={styles.quietPeriod}>
            <div>
              <label className={styles.inlineLabel} htmlFor={`pc-qp-start-${i}`}>
                From
              </label>
              <input
                id={`pc-qp-start-${i}`}
                type="time"
                className={styles.rowInput}
                value={q.start}
                onChange={(e) => updateQuietPeriod(i, { start: e.target.value })}
                disabled={busy}
              />
            </div>
            <div>
              <label className={styles.inlineLabel} htmlFor={`pc-qp-end-${i}`}>
                To
              </label>
              <input
                id={`pc-qp-end-${i}`}
                type="time"
                className={styles.rowInput}
                value={q.end}
                onChange={(e) => updateQuietPeriod(i, { end: e.target.value })}
                disabled={busy}
              />
            </div>
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              onClick={() => removeQuietPeriod(i)}
              disabled={busy}
              aria-label={`Remove quiet period ${i + 1}`}
            >
              Remove
            </button>
            <div className={styles.quietDays} role="group" aria-label="Days">
              {WEEKDAYS.map((d) => (
                <label key={d} className={styles.dayChip}>
                  <input
                    type="checkbox"
                    checked={(q.days ?? []).includes(d)}
                    onChange={() => toggleDay(i, d)}
                    disabled={busy}
                  />
                  {d}
                </label>
              ))}
            </div>
            <div className={styles.muted} style={{ gridColumn: "1 / -1", fontSize: "0.76rem" }}>
              Timezone: {q.timezone || guessTimezone()}
            </div>
          </div>
        ))}
        <button
          type="button"
          className="sg-btn sg-btn--outline sg-btn--sm"
          onClick={addQuietPeriod}
          disabled={busy}
        >
          + Add quiet period
        </button>
      </fieldset>

      {/* Pause ----------------------------------------------------------- */}
      <fieldset className={styles.fieldset}>
        <legend className={styles.legend}>Pause contact</legend>
        <label className={styles.inlineLabel} htmlFor="pc-pause">
          Pause all contact for this subscription until:
        </label>
        <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
          <input
            id="pc-pause"
            type="date"
            className={styles.rowInput}
            value={pauseUntil}
            onChange={(e) => setPauseUntil(e.target.value)}
            disabled={busy}
            style={{ maxWidth: 200 }}
          />
          {pauseUntil && (
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              onClick={() => setPauseUntil("")}
              disabled={busy}
            >
              Clear
            </button>
          )}
        </div>
      </fieldset>

      {error && <InlineAlert variant="error">{error}</InlineAlert>}
    </Modal>
  );
}

function describeError(e: unknown): string {
  if (e instanceof PcApiError) {
    if (e.status === 404) return "This subscription is no longer available.";
    if (e.status === 422) return e.message || "Some values were not accepted.";
    if (e.status === 409) return "This list is no longer available.";
    if (e.status === 405 || e.status === 501)
      return "Saving preferences isn’t available yet — the backend endpoint is still being finished.";
  }
  return e instanceof Error ? e.message : "Could not save preferences.";
}
