"use client";

import { type ReactNode, type RefObject, useState } from "react";
import "./inspector.css";
import { riskBandFor } from "@/lib/holograph/analysis";
import type { GraphNode } from "@/lib/holograph/types";

export interface InspectorProps {
  collapsed: boolean;
  node: GraphNode | null;
  onUpdate: (message: string, mutate: (node: GraphNode) => GraphNode) => void;
  nameRef: RefObject<HTMLInputElement | null>;
}

type SectionId = "element" | "members" | "aspects" | "metrics" | "notes";

function splitLines(value: string) {
  return value
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
}

function memberRow(entry: string, key: string) {
  const [head, tail] = entry.split(/\s*:\s*(.+)/, 2);
  return (
    <span key={key}>
      {head}
      {tail ? (
        <>
          {" : "}
          <i>{tail}</i>
        </>
      ) : null}
    </span>
  );
}

/** Module-level so the section bodies are not remounted on every workspace render —
 * the inspector's uncontrolled inputs would otherwise lose focus and pending edits. */
function Section({
  title,
  closed,
  onToggle,
  children,
}: {
  title: string;
  closed: boolean;
  onToggle: () => void;
  children: ReactNode;
}) {
  return (
    <div className={closed ? "trd-isec is-closed" : "trd-isec"}>
      <h3>
        <button type="button" aria-expanded={!closed} onClick={onToggle}>
          {title}
        </button>
      </h3>
      <div className="trd-ibody">{children}</div>
    </div>
  );
}

export function Inspector({ collapsed, node, onUpdate, nameRef }: InspectorProps) {
  const [closed, setClosed] = useState<Record<SectionId, boolean>>({
    element: false,
    members: false,
    aspects: true,
    metrics: true,
    notes: true,
  });

  const toggle = (id: SectionId) => () => setClosed((current) => ({ ...current, [id]: !current[id] }));

  const attributes = node?.uml?.attributes ?? [];
  const operations = node?.uml?.operations ?? [];

  return (
    <aside
      className={collapsed ? "trd-inspector is-collapsed" : "trd-inspector"}
      aria-label="Inspector panel"
      inert={collapsed}
    >
      <Section title="Element" closed={closed.element} onToggle={toggle("element")}>
        {node ? (
          <>
            <div className="trd-field">
              <label htmlFor="trd-insp-name">Name</label>
              <input
                id="trd-insp-name"
                ref={nameRef}
                key={`${node.id}:label`}
                aria-label="Element name"
                defaultValue={node.label}
                onBlur={(event) => {
                  const value = event.target.value.trim();
                  if (value && value !== node.label) {
                    onUpdate(`Renamed to ${value}`, (current) => ({ ...current, label: value }));
                  }
                }}
              />
            </div>
            <div className="trd-field">
              <label htmlFor="trd-insp-stereotype">Stereotype</label>
              <input
                id="trd-insp-stereotype"
                key={`${node.id}:stereotype`}
                defaultValue={node.stereotype ?? ""}
                onBlur={(event) => {
                  const value = event.target.value.trim();
                  if (value !== (node.stereotype ?? "")) {
                    onUpdate(`Updated stereotype of ${node.label}`, (current) => ({
                      ...current,
                      stereotype: value || undefined,
                    }));
                  }
                }}
              />
            </div>
            <div className="trd-field">
              <label htmlFor="trd-insp-package">Package</label>
              <input
                id="trd-insp-package"
                key={`${node.id}:package`}
                defaultValue={node.packageName ?? ""}
                onBlur={(event) => {
                  const value = event.target.value.trim();
                  if (value !== (node.packageName ?? "")) {
                    onUpdate(`Updated package of ${node.label}`, (current) => ({
                      ...current,
                      packageName: value || undefined,
                    }));
                  }
                }}
              />
            </div>
            <div className="trd-field">
              <label htmlFor="trd-insp-status">Status</label>
              <select
                id="trd-insp-status"
                value={node.status ?? "draft"}
                onChange={(event) => {
                  const value = event.target.value as NonNullable<GraphNode["status"]>;
                  onUpdate(`Set ${node.label} status to ${value}`, (current) => ({ ...current, status: value }));
                }}
              >
                {(["stable", "draft", "review", "hot"] as const).map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </div>
          </>
        ) : (
          <p className="trd-empty-note">No element selected.</p>
        )}
      </Section>

      <Section title="Members" closed={closed.members} onToggle={toggle("members")}>
        {node ? (
          <>
            <div className="trd-members">
              {attributes.length + operations.length === 0 ? (
                <span>no members</span>
              ) : (
                [...attributes, ...operations].map((entry, index) => memberRow(entry, `${node.id}:m:${index}`))
              )}
            </div>
            <div className="trd-field">
              <label htmlFor="trd-insp-attributes">Attributes (one per line)</label>
              <textarea
                id="trd-insp-attributes"
                key={`${node.id}:attributes`}
                rows={3}
                defaultValue={attributes.join("\n")}
                onBlur={(event) => {
                  const next = splitLines(event.target.value);
                  if (JSON.stringify(next) !== JSON.stringify(attributes)) {
                    onUpdate(`Updated attributes of ${node.label}`, (current) => ({
                      ...current,
                      uml: { ...current.uml, attributes: next },
                      members: [...next, ...(current.uml?.operations ?? [])],
                    }));
                  }
                }}
              />
            </div>
            <div className="trd-field">
              <label htmlFor="trd-insp-operations">Operations (one per line)</label>
              <textarea
                id="trd-insp-operations"
                key={`${node.id}:operations`}
                rows={3}
                defaultValue={operations.join("\n")}
                onBlur={(event) => {
                  const next = splitLines(event.target.value);
                  if (JSON.stringify(next) !== JSON.stringify(operations)) {
                    onUpdate(`Updated operations of ${node.label}`, (current) => ({
                      ...current,
                      uml: { ...current.uml, operations: next },
                      members: [...(current.uml?.attributes ?? []), ...next],
                    }));
                  }
                }}
              />
            </div>
          </>
        ) : (
          <p className="trd-empty-note">No element selected.</p>
        )}
      </Section>

      <Section title="Aspects" closed={closed.aspects} onToggle={toggle("aspects")}>
        <p className="trd-empty-note">Aspect registry is not part of this build.</p>
      </Section>

      <Section title="Metrics" closed={closed.metrics} onToggle={toggle("metrics")}>
        {node ? (
          <>
            <div className="trd-members">
              <span>
                complexity {node.metrics.complexity} · churn {node.metrics.churn} · risk {node.metrics.risk}
              </span>
            </div>
            {(["complexity", "churn", "risk"] as const).map((metric) => (
              <div className="trd-field" key={metric}>
                <label htmlFor={`trd-insp-${metric}`}>
                  {metric[0].toUpperCase() + metric.slice(1)} — {riskBandFor(node.metrics[metric])}
                </label>
                <input
                  id={`trd-insp-${metric}`}
                  key={`${node.id}:${metric}`}
                  type="number"
                  min={0}
                  max={100}
                  defaultValue={node.metrics[metric]}
                  onBlur={(event) => {
                    const value = Math.max(0, Math.min(100, Number.parseInt(event.target.value, 10)));
                    if (!Number.isNaN(value) && value !== node.metrics[metric]) {
                      onUpdate(`Updated ${metric} of ${node.label}`, (current) => ({
                        ...current,
                        metrics: { ...current.metrics, [metric]: value },
                      }));
                    }
                  }}
                />
              </div>
            ))}
          </>
        ) : (
          <p className="trd-empty-note">No element selected.</p>
        )}
      </Section>

      <Section title="Notes" closed={closed.notes} onToggle={toggle("notes")}>
        {node ? (
          <div className="trd-field">
            <textarea
              key={`${node.id}:notes`}
              aria-label="Element notes"
              rows={3}
              defaultValue={node.description}
              onBlur={(event) => {
                const value = event.target.value.trim();
                if (value !== node.description) {
                  onUpdate(`Updated notes of ${node.label}`, (current) => ({
                    ...current,
                    description: value || `${current.label} UML element.`,
                  }));
                }
              }}
            />
          </div>
        ) : (
          <p className="trd-empty-note">No element selected.</p>
        )}
      </Section>
    </aside>
  );
}
