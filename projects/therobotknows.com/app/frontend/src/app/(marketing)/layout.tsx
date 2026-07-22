import { MarketingHeader } from "@/components/layout/marketing-header";

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-page bg-paper-grain text-ink">
      <MarketingHeader />
      {children}
      <footer className="border-t border-rule-subtle mt-20">
        <div className="mx-auto max-w-6xl px-6 py-10 flex flex-col sm:flex-row gap-4 sm:items-center sm:justify-between">
          <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-ink-tertiary">
            TheRobotKnows · Knowledge that stays consistent
          </p>
          <div className="flex gap-4 font-sans text-[13px] text-ink-secondary">
            <a href="/login" className="hover:text-ink">
              Sign in
            </a>
            <a href="/register" className="hover:text-ink">
              Free beta
            </a>
            <a href="https://noizu.com" className="hover:text-ink">
              Noizu Labs
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
