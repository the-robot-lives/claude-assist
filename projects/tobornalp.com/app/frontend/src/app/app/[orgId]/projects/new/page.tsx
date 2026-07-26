"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api, type Methodology } from "@/lib/api";
import { useMutation } from "@/lib/use-api";
import { Btn, Button, Input, Textarea, FieldLabel } from "@/components/ui";
import { MethodologyPicker, templateFor } from "@/components/pm/methodology-picker";

// Derive a URL slug from a display name: lowercase, non-alnum → hyphen, trimmed.
function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
}

// Derive a 2–16 char uppercase-alnum key prefix from a slug.
function derivePrefix(slug: string): string {
  return slug.replace(/[^a-z0-9]/gi, "").toUpperCase().slice(0, 6);
}

export default function NewProjectPage() {
  const params = useParams<{ orgId: string }>();
  const router = useRouter();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [step, setStep] = useState(1);
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [keyPrefix, setKeyPrefix] = useState("");
  const [prefixTouched, setPrefixTouched] = useState(false);
  const [description, setDescription] = useState("");
  const [methodology, setMethodology] = useState<Methodology>("kanban");

  // Auto-derived values (unless the field was hand-edited).
  const effectiveSlug = slugTouched ? slug : slugify(name);
  const effectivePrefix = prefixTouched ? keyPrefix : derivePrefix(effectiveSlug);
  const template = useMemo(() => templateFor(methodology), [methodology]);

  const create = useMutation(() =>
    api.createProject(orgId, {
      name: name.trim(),
      slug: effectiveSlug,
      methodology,
      key_prefix: effectivePrefix || undefined,
      description: description.trim() || undefined,
    }),
  );

  const detailsValid = name.trim().length > 0 && effectiveSlug.length > 0;

  const submit = async () => {
    try {
      const res = await create.trigger();
      toast.success("Project created");
      router.push(`/app/${orgId}/projects/${res.project.id}`);
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  return (
    <div className="app-content max-w-2xl">
      <header>
        <Link href={`/app/${orgId}/projects`} className="text-xs text-faint hover:text-ink">
          ← projects
        </Link>
        <h1 className="mt-1 text-[13px] font-bold uppercase tracking-[0.1em] text-ink">new project</h1>
        <ol className="mt-3 flex overflow-hidden rounded-pill border border-line text-[11px] uppercase tracking-wide">
          {["details", "methodology", "confirm"].map((label, i) => {
            const n = i + 1;
            const state = n < step ? "done" : n === step ? "current" : "future";
            return (
              <li
                key={label}
                className={`px-3 py-1 ${
                  state === "current"
                    ? "bg-acc font-bold text-black"
                    : state === "done"
                      ? "bg-panel2 text-mut"
                      : "text-faint"
                }`}
              >
                {n}. {label}
              </li>
            );
          })}
        </ol>
      </header>

      {step === 1 && (
        <div className="space-y-4 rounded-panel border border-line bg-panel p-4 shadow-card">
          <FieldLabel label="name" required>
            <Input
              value={name}
              autoFocus
              placeholder="e.g. Apollo"
              onChange={(e) => setName(e.target.value)}
            />
          </FieldLabel>
          <FieldLabel label="slug" hint="lowercase, used in URLs. auto-derived from the name.">
            <Input
              value={effectiveSlug}
              placeholder="apollo"
              onChange={(e) => {
                setSlugTouched(true);
                setSlug(e.target.value);
              }}
            />
          </FieldLabel>
          <FieldLabel label="key prefix" hint="2–16 uppercase chars for item keys (e.g. APL-12).">
            <Input
              value={effectivePrefix}
              placeholder="APL"
              onChange={(e) => {
                setPrefixTouched(true);
                setKeyPrefix(e.target.value.toUpperCase());
              }}
            />
          </FieldLabel>
          <FieldLabel label="description">
            <Textarea
              value={description}
              rows={3}
              placeholder="what is this project for?"
              onChange={(e) => setDescription(e.target.value)}
            />
          </FieldLabel>
          <div className="flex justify-end">
            <Btn variant="primary" disabled={!detailsValid} onClick={() => setStep(2)}>
              next
            </Btn>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4 rounded-panel border border-line bg-panel p-4 shadow-card">
          <p className="text-sm text-mut">
            choose how your team works. this seeds the project&apos;s board — you can change it
            later.
          </p>
          <MethodologyPicker value={methodology} onChange={setMethodology} />
          <div className="flex justify-between">
            <Button size="sm" variant="outline" onClick={() => setStep(1)}>
              back
            </Button>
            <Btn variant="primary" onClick={() => setStep(3)}>
              next
            </Btn>
          </div>
        </div>
      )}

      {step === 3 && (
        <div className="space-y-4 rounded-panel border border-line bg-panel p-4 shadow-card">
          <h2 className="text-[12px] font-bold uppercase tracking-[0.1em] text-ink">confirm</h2>
          <dl className="grid grid-cols-[8rem_1fr] gap-y-2 text-sm">
            <dt className="text-faint">name</dt>
            <dd className="text-ink">{name}</dd>
            <dt className="text-faint">slug</dt>
            <dd className="text-ink">{effectiveSlug}</dd>
            {effectivePrefix && (
              <>
                <dt className="text-faint">key prefix</dt>
                <dd className="text-ink">{effectivePrefix}</dd>
              </>
            )}
            <dt className="text-faint">methodology</dt>
            <dd className="text-ink">
              {template.label}
              <span className="text-faint">
                {" "}
                · {template.stages.length} stage{template.stages.length === 1 ? "" : "s"}
                {template.iteration ? ` + ${template.iteration}` : ""}
              </span>
            </dd>
          </dl>
          <div className="flex justify-between">
            <Button size="sm" variant="outline" onClick={() => setStep(2)}>
              back
            </Button>
            <Btn variant="primary" disabled={create.loading} onClick={submit}>
              {create.loading ? "creating…" : "create project"}
            </Btn>
          </div>
        </div>
      )}
    </div>
  );
}
