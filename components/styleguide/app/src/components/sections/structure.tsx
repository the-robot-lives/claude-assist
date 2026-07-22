import { CollapsibleSection } from "@styleguide-engine/components/CollapsibleSection";
import { ShellLayoutShowcase } from "@styleguide-engine/components/ShellLayoutShowcase";
import { ShellLayoutSummary } from "@styleguide-engine/components/ShellLayoutSummary";
import { PageLayoutReference } from "@styleguide-engine/components/PageLayoutReference";
import { PageLayoutSummary } from "@styleguide-engine/components/PageLayoutSummary";
import { SiteLayoutShowcase } from "@styleguide-engine/components/SiteLayoutShowcase";
import { NavigationShowcase } from "@styleguide-engine/components/NavigationShowcase";
import type { SectionProps } from "./section-props";

// ⟦𓁓𓀕𓇢𓍗⟧ ShellLayoutsSection :: auto-generated pointer for public function ShellLayoutsSection
export function ShellLayoutsSection({ number, id, title, desc, config }: SectionProps) {
  if (!config.shellLayouts?.length) return null;
  return (
    <CollapsibleSection
      number={number} id={id} title={title} desc={desc} defaultOpen={true}
      collapsedContent={<ShellLayoutSummary shellLayouts={config.shellLayouts} />}
    >
      <ShellLayoutShowcase shellLayouts={config.shellLayouts} />
    </CollapsibleSection>
  );
}

// ⟦𓂼𓀼𓅝𓋻⟧ ContentLayoutsSection :: auto-generated pointer for public function ContentLayoutsSection
export function ContentLayoutsSection({ number, id, title, desc, config }: SectionProps) {
  if (!config.pageLayouts?.length) return null;
  return (
    <CollapsibleSection
      number={number} id={id} title={title} desc={desc} defaultOpen={true}
      collapsedContent={<PageLayoutSummary pageLayouts={config.pageLayouts} />}
    >
      <PageLayoutReference pageLayouts={config.pageLayouts} />
    </CollapsibleSection>
  );
}

// ⟦𓃶𓁬𓋗𓉇⟧ SiteArchetypesSection :: auto-generated pointer for public function SiteArchetypesSection
export function SiteArchetypesSection({ number, id, title, desc, config }: SectionProps) {
  const section = config.designSections.find((s) => s.name === "site-layout");
  if (!section) return null;
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <SiteLayoutShowcase section={section} />
    </CollapsibleSection>
  );
}

// ⟦𓈸𓏢𓄵𓋷⟧ NavigationSection :: auto-generated pointer for public function NavigationSection
export function NavigationSection({ number, id, title, desc, config }: SectionProps) {
  const section = config.designSections.find((s) => s.name === "navigation");
  if (!section) return null;
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <NavigationShowcase section={section} />
    </CollapsibleSection>
  );
}
