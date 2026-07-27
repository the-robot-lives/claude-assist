'use client';

import Link from "next/link";
import { usePathname, useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { useAuth } from "@/context/auth";
import { Fragment, ReactNode, useEffect, useState } from "react";
import {
  Dialog as HDialog,
  DialogPanel,
  DialogTitle,
  Transition,
  TransitionChild,
} from "@headlessui/react";
import { cn } from "@/lib/cn";
import { Avatar, btnClass } from "@/components/ui";

// Org-scoped app shell: 212px rail + topbar, per design/concept-dark-neon.
// Rendered inside [orgId]/layout so it only appears within an org context.
// `usePathname` highlights the active section.
//
// SECTIONS is the whole navigation surface — every entry points at a route that
// already exists under src/app/app/[orgId]/. Add/remove links here, nowhere else.
type Section = { slug: string; label: string; glyph: string; sect?: string };

const SECTIONS: Section[] = [
  { slug: "today", label: "today", glyph: "◉" },
  { slug: "inbox", label: "inbox", glyph: "▤" },
  { slug: "personal", label: "personal", glyph: "▢" },
  { slug: "items", label: "items", glyph: "☰", sect: "work" },
  { slug: "projects", label: "projects", glyph: "◫" },
  { slug: "goals", label: "goals", glyph: "◎" },
  { slug: "wiki", label: "wiki", glyph: "✎" },
  { slug: "reviews", label: "reviews", glyph: "✓" },
  { slug: "members", label: "members", glyph: "◈", sect: "platform" },
  { slug: "artifacts", label: "artifacts", glyph: "⧉" },
  { slug: "ticket-types", label: "ticket types", glyph: "◇" },
  { slug: "ticket-fields", label: "ticket fields", glyph: "◆" },
];

export function OrgNav({ children }: { children: ReactNode }) {
  const { currentOrg, organizations, switchOrg } = useOrg();
  const { user, logout } = useAuth();
  const pathname = usePathname();
  const params = useParams<{ orgId?: string }>();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Prefer the context's resolved id; fall back to the URL segment so the rail
  // renders during the first paint rather than popping in after orgs load.
  const routeOrgId = Array.isArray(params?.orgId) ? params.orgId[0] : params?.orgId;
  const orgId = currentOrg?.id ?? routeOrgId;

  const section = pathname?.split("/")[3];
  const current = SECTIONS.find((s) => s.slug === section);

  // The rail is hidden below 900px (see `min-[900px]:flex` below); the drawer
  // carries the same nav there, so a route change should always close it —
  // Link clicks close it directly too, this is the safety net (back/forward,
  // programmatic nav).
  useEffect(() => {
    setMobileNavOpen(false);
  }, [pathname]);

  return (
    <div className="flex min-h-screen">
      {orgId && (
        <aside className="hidden w-[212px] flex-none flex-col border-r border-line bg-panel pt-3.5 pb-2.5 min-[900px]:flex">
          <NavRailContent
            orgId={orgId}
            pathname={pathname}
            currentOrgName={currentOrg?.name}
            organizations={organizations}
            currentOrgId={currentOrg?.id}
            onSwitch={switchOrg}
            userEmail={user?.email}
            onLogout={logout}
          />
        </aside>
      )}

      {orgId && (
        <Transition show={mobileNavOpen} as={Fragment}>
          <HDialog as="div" className="relative z-50 min-[900px]:hidden" onClose={() => setMobileNavOpen(false)}>
            <TransitionChild
              as={Fragment}
              enter="ease-out duration-200 motion-reduce:duration-0"
              enterFrom="opacity-0"
              enterTo="opacity-100"
              leave="ease-in duration-150 motion-reduce:duration-0"
              leaveFrom="opacity-100"
              leaveTo="opacity-0"
            >
              <div className="fixed inset-0 bg-black/60" aria-hidden="true" />
            </TransitionChild>

            <TransitionChild
              as={Fragment}
              enter="ease-out duration-200 motion-reduce:duration-0 motion-reduce:transform-none"
              enterFrom="-translate-x-full"
              enterTo="translate-x-0"
              leave="ease-in duration-150 motion-reduce:duration-0 motion-reduce:transform-none"
              leaveFrom="translate-x-0"
              leaveTo="-translate-x-full"
            >
              <DialogPanel className="fixed inset-y-0 left-0 flex w-full max-w-[280px] flex-col border-r border-line bg-panel pt-3.5 pb-2.5">
                <DialogTitle className="sr-only">navigation</DialogTitle>
                <NavRailContent
                  orgId={orgId}
                  pathname={pathname}
                  currentOrgName={currentOrg?.name}
                  organizations={organizations}
                  currentOrgId={currentOrg?.id}
                  onSwitch={switchOrg}
                  userEmail={user?.email}
                  onLogout={logout}
                  onNavigate={() => setMobileNavOpen(false)}
                />
              </DialogPanel>
            </TransitionChild>
          </HDialog>
        </Transition>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex items-center gap-3 border-b border-line bg-panel px-[18px] py-[9px] text-[12px]">
          {orgId && (
            <button
              type="button"
              aria-expanded={mobileNavOpen}
              aria-label="open navigation menu"
              onClick={() => setMobileNavOpen(true)}
              className={cn(btnClass("default"), "min-[900px]:hidden")}
            >
              ≡ menu
            </button>
          )}

          <span className="text-mut">
            {currentOrg?.name ?? "org"} / <b className="font-bold text-ink">{current?.label ?? section ?? "app"}</b>
          </span>

          {/* Visual placeholder for the ⌘K palette — not wired to anything yet,
              so it is hidden from assistive tech rather than posing as a control. */}
          <div
            aria-hidden="true"
            className="ml-auto hidden min-w-[220px] items-center gap-2 rounded-pill border border-line2 bg-ground px-3.5 py-[5px] text-faint min-[900px]:flex"
          >
            ⌕ jump to anything…
            <span className="ml-auto rounded-[5px] border border-line2 border-b-2 bg-panel2 px-1.5 py-px text-[10px] text-mut">
              ⌘K
            </span>
          </div>

          <Link href="/app?create=1" className={btnClass("default", "ml-auto min-[900px]:ml-0")}>
            + org
          </Link>
        </div>

        <main className="min-w-0 flex-1">{children}</main>
      </div>
    </div>
  );
}

// Shared nav content: org selector, section links, org-switch/create, user
// footer. Rendered by both the >=900px rail and the <900px drawer so the link
// list only exists in one place. `onNavigate` (drawer only) closes the drawer
// on link/logout activation, ahead of the route-change effect in OrgNav.
function NavRailContent({
  orgId,
  pathname,
  currentOrgName,
  organizations,
  currentOrgId,
  onSwitch,
  userEmail,
  onLogout,
  onNavigate,
}: {
  orgId: string;
  pathname: string | null;
  currentOrgName?: string;
  organizations: { id: string; name: string }[];
  currentOrgId?: string;
  onSwitch: (id: string) => void;
  userEmail?: string;
  onLogout: () => void;
  onNavigate?: () => void;
}) {
  return (
    <>
      <OrgSelector
        name={currentOrgName ?? "organization"}
        orgs={organizations}
        currentId={currentOrgId}
        onSwitch={onSwitch}
      />

      <nav className="flex flex-col gap-0.5 px-2.5">
        {SECTIONS.map((s) => {
          const href = `/app/${orgId}/${s.slug}`;
          const active = pathname === href || pathname?.startsWith(`${href}/`);
          return (
            <div key={s.slug} className="contents">
              {s.sect && (
                <span className="mx-2.5 mt-3 mb-1 text-[10px] uppercase tracking-[0.14em] text-faint">
                  {s.sect}
                </span>
              )}
              <Link
                href={href}
                aria-current={active ? "page" : undefined}
                onClick={onNavigate}
                className={cn(
                  "flex items-center gap-[9px] rounded-lg px-2.5 py-1.5 text-[12.5px] no-underline",
                  active
                    ? "bg-acc-bg font-bold text-acc"
                    : "text-mut hover:bg-sel hover:text-ink",
                )}
              >
                <span className={cn("w-3.5 text-center", active ? "text-acc" : "text-faint")}>
                  {s.glyph}
                </span>
                {s.label}
              </Link>
            </div>
          );
        })}

        {/* Switch between orgs or create a new one (owner of many). The
            ?create=1 intent flag stops the single-org auto-redirect on /app. */}
        <Link
          href="/app?create=1"
          onClick={onNavigate}
          className="mt-3 rounded-lg border-t border-line px-2.5 pt-3 text-[12px] text-mut no-underline hover:text-ink"
        >
          + new organization
        </Link>
      </nav>

      <div className="mt-auto border-t border-line px-3.5 pt-2.5">
        <div className="flex items-center gap-2 text-[12px] text-mut">
          <Avatar name={userEmail} />
          <Link
            href="/app/profile"
            onClick={onNavigate}
            className="min-w-0 flex-1 truncate no-underline hover:text-ink"
            title={userEmail}
          >
            {userEmail ?? "settings"}
          </Link>
        </div>
        <button
          onClick={() => {
            onNavigate?.();
            onLogout();
          }}
          className="mt-2 text-[11px] text-faint hover:text-err"
        >
          log out
        </button>
      </div>
    </>
  );
}

// Org selector card at the top of the rail. Renders a real <select> when the
// user belongs to more than one org; a static label otherwise.
function OrgSelector({
  name,
  orgs,
  currentId,
  onSwitch,
}: {
  name: string;
  orgs: { id: string; name: string }[];
  currentId?: string;
  onSwitch: (id: string) => void;
}) {
  const card =
    "mx-3 mb-3.5 flex items-center justify-between gap-2 rounded-card border border-line2 bg-panel2 px-3 py-2 text-[12px]";

  if (orgs.length <= 1) {
    return (
      <div className={card}>
        <b className="truncate font-bold text-ink">{name}</b>
      </div>
    );
  }

  return (
    <label className={card}>
      <span className="sr-only">switch organization</span>
      <select
        value={currentId ?? ""}
        onChange={(e) => onSwitch(e.target.value)}
        className="min-w-0 flex-1 cursor-pointer appearance-none truncate bg-transparent font-bold text-ink outline-none"
      >
        {orgs.map((o) => (
          <option key={o.id} value={o.id} className="bg-panel2 text-ink">
            {o.name}
          </option>
        ))}
      </select>
      <span aria-hidden="true" className="text-faint">▾</span>
    </label>
  );
}
