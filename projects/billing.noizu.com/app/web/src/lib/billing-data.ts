export type InvoiceStatus =
  | "draft"
  | "sent"
  | "viewed"
  | "partially_paid"
  | "paid"
  | "overdue"
  | "void"
  | "written_off";

export type Money = {
  amount: number;
  currency: "USD";
};

export type Invoice = {
  id: string;
  number: string;
  customer: string;
  project: string;
  status: InvoiceStatus;
  total: Money;
  balanceDue: Money;
  dueDate: string;
  nextAction: string;
};

export type CustomerPressure = {
  id: string;
  name: string;
  status: string;
  balance: Money;
  risk: "low" | "medium" | "high";
};

export type AuditEvent = {
  id: string;
  event: string;
  actor: string;
  occurredAt: string;
};

export const invoices: Invoice[] = [];

export const customers: CustomerPressure[] = [];

export const auditEvents: AuditEvent[] = [];

export function formatMoney(money: Money): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: money.currency,
    maximumFractionDigits: 0,
  }).format(money.amount / 100);
}

export const receivablesSummary = {
  outstanding: null as Money | null,
  overdue: null as Money | null,
  paidThisMonth: null as Money | null,
  collectionRiskCount: null as number | null,
  openInvoiceCount: null as number | null,
};

export const integrationReadiness = [
  { label: "Phoenix API", state: "Contract drafted", tone: "info" },
  { label: "PostgreSQL ledger", state: "Schema pending", tone: "warning" },
  { label: "Stripe webhooks", state: "Not connected", tone: "danger" },
  { label: "PDF worker", state: "Not connected", tone: "danger" },
] as const;
