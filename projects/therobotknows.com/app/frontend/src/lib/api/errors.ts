export class ApiError extends Error {
  status: number;
  fieldErrors?: Record<string, string[]>;

  constructor(
    message: string,
    status: number,
    fieldErrors?: Record<string, string[]>,
  ) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.fieldErrors = fieldErrors;
  }
}

export function messageFromBody(body: unknown, fallback: string): string {
  if (!body || typeof body !== "object") return fallback;
  const b = body as Record<string, unknown>;
  if (typeof b.error === "string") return b.error;
  if (b.errors && typeof b.errors === "object") {
    const errors = b.errors as Record<string, string[] | string>;
    const first = Object.values(errors)[0];
    if (Array.isArray(first) && first[0]) return first[0];
    if (typeof first === "string") return first;
  }
  return fallback;
}

export function fieldErrorsFromBody(
  body: unknown,
): Record<string, string[]> | undefined {
  if (!body || typeof body !== "object") return undefined;
  const errors = (body as Record<string, unknown>).errors;
  if (!errors || typeof errors !== "object") return undefined;
  const out: Record<string, string[]> = {};
  for (const [k, v] of Object.entries(errors as Record<string, unknown>)) {
    if (Array.isArray(v)) out[k] = v.map(String);
    else if (typeof v === "string") out[k] = [v];
  }
  return Object.keys(out).length ? out : undefined;
}
