"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api, type Methodology } from "@/lib/api";
import { useMutation } from "@/lib/use-api";
import { Button, Input, Textarea, FieldLabel } from "@/components/ui";
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
    <div className="mx-auto max-w-2xl px-4 py-6">
      <header className="mb-6">
        <Link href={`/app/${orgId}/projects`} className="text-xs text-text-muted hover:text-text">
          ← Projects
        </Link>
        <h1 className="mt-1 text-2xl font-bold text-text">New project</h1>
        <ol className="mt-3 flex gap-2 text-xs text-text-muted">
          {["Details", "Methodology", "Confirm"].map((label, i) => (
            <li
              key={label}
              className={`rounded px-2 py-0.5 ${
                step === i + 1 ? "bg-surface-alt font-medium text-text" : ""
              }`}
            >
              {i + 1}. {label}
            </li>
          ))}
        </ol>
      </header>

      {step === 1 && (
        <div className="space-y-4 rounded-lg border border-border bg-surface p-4">
          <FieldLabel label="Name" required>
            <Input
              value={name}
              autoFocus
              placeholder="e.g. Apollo"
              onChange={(e) => setName(e.target.value)}
            />
          </FieldLabel>
          <FieldLabel label="Slug" hint="Lowercase, used in URLs. Auto-derived from the name.">
            <Input
              value={effectiveSlug}
              placeholder="apollo"
              onChange={(e) => {
                setSlugTouched(true);
                setSlug(e.target.value);
              }}
            />
          </FieldLabel>
          <FieldLabel label="Key prefix" hint="2–16 uppercase chars for item keys (e.g. APL-12).">
            <Input
              value={effectivePrefix}
              placeholder="APL"
              onChange={(e) => {
                setPrefixTouched(true);
                setKeyPrefix(e.target.value.toUpperCase());
              }}
            />
          </FieldLabel>
          <FieldLabel label="Description">
            <Textarea
              value={description}
              rows={3}
              placeholder="What is this project for?"
              onChange={(e) => setDescription(e.target.value)}
            />
          </FieldLabel>
          <div className="flex justify-end">
            <Button size="sm" disabled={!detailsValid} onClick={() => setStep(2)}>
              Next
            </Button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4 rounded-lg border border-border bg-surface p-4">
          <p className="text-sm text-text-secondary">
            Choose how your team works. This seeds the project&apos;s board — you can change it
            later.
          </p>
          <MethodologyPicker value={methodology} onChange={setMethodology} />
          <div className="flex justify-between">
            <Button size="sm" variant="outline" onClick={() => setStep(1)}>
              Back
            </Button>
            <Button size="sm" onClick={() => setStep(3)}>
              Next
            </Button>
          </div>
        </div>
      )}

      {step === 3 && (
        <div className="space-y-4 rounded-lg border border-border bg-surface p-4">
          <h2 className="text-sm font-semibold text-text">Confirm</h2>
          <dl className="grid grid-cols-[8rem_1fr] gap-y-2 text-sm">
            <dt className="text-text-muted">Name</dt>
            <dd className="text-text">{name}</dd>
            <dt className="text-text-muted">Slug</dt>
            <dd className="text-text">{effectiveSlug}</dd>
            {effectivePrefix && (
              <>
                <dt className="text-text-muted">Key prefix</dt>
                <dd className="text-text">{effectivePrefix}</dd>
              </>
            )}
            <dt className="text-text-muted">Methodology</dt>
            <dd className="text-text">
              {template.label}
              <span className="text-text-muted">
                {" "}
                · {template.stages.length} stage{template.stages.length === 1 ? "" : "s"}
                {template.iteration ? ` + ${template.iteration}` : ""}
              </span>
            </dd>
          </dl>
          <div className="flex justify-between">
            <Button size="sm" variant="outline" onClick={() => setStep(2)}>
              Back
            </Button>
            <Button size="sm" disabled={create.loading} onClick={submit}>
              {create.loading ? "Creating…" : "Create project"}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
