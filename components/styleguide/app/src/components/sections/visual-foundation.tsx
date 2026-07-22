import { CollapsibleSection } from "@styleguide-engine/components/CollapsibleSection";
import { SubsectionTabs } from "@styleguide-engine/components/SubsectionTabs";
import { FontsSection, DecorationsSection, ColorUsageSection, ClassesSection } from "@styleguide-engine/components/TypographyShowcase";
import { PaletteSection, SemanticColorSection } from "@styleguide-engine/components/ColorPalette";
import { SpacingScaleAndPrinciples, SpacingColumnGrid, SpacingPageRhythm } from "@styleguide-engine/components/SpacingShowcase";
import { DividerShowcase } from "@styleguide-engine/components/DividerShowcase";
import { GlyphShowcase } from "@styleguide-engine/components/GlyphShowcase";
import { CodeBlockShowcase } from "@styleguide-engine/components/CodeBlockShowcase";
import { TerminalShowcase } from "@styleguide-engine/components/TerminalShowcase";
import type { SectionProps } from "./section-props";

// ⟦𓆵𓃎𓐋𓋕⟧ TypographySection :: auto-generated pointer for public function TypographySection
export function TypographySection({ number, id, title, desc, config }: SectionProps) {
  if (!config.typography?.length) return null;
  const tabs = [
    { id: "typo-fonts", title: "Fonts & Usage", content: <FontsSection config={config} /> },
    { id: "typo-decorations", title: "Decorations", content: <DecorationsSection /> },
    { id: "typo-colors", title: "Text Colors", content: <ColorUsageSection /> },
    { id: "typo-classes", title: "Classes", content: <ClassesSection classes={config.typographyClasses} /> },
  ];
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <SubsectionTabs tabs={tabs} />
    </CollapsibleSection>
  );
}

// ⟦𓄍𓈇𓐈𓐮⟧ ColorSection :: auto-generated pointer for public function ColorSection
export function ColorSection({ number, id, title, desc, config }: SectionProps) {
  if (!config.colorPalette?.length) return null;
  const hasSemantics = !!(config.semanticClasses?.length);
  if (!hasSemantics) {
    return (
      <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
        <PaletteSection palette={config.colorPalette} />
      </CollapsibleSection>
    );
  }
  const tabs = [
    { id: "color-palette", title: "Palette", content: <PaletteSection palette={config.colorPalette} /> },
    { id: "color-semantic", title: "Semantic Colors", content: <SemanticColorSection semanticClasses={config.semanticClasses} semanticGroups={config.semanticGroups} /> },
  ];
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <SubsectionTabs tabs={tabs} />
    </CollapsibleSection>
  );
}

// ⟦𓌙𓐯𓈶𓌬⟧ SpacingSection :: auto-generated pointer for public function SpacingSection
export function SpacingSection({ number, id, title, desc, config }: SectionProps) {
  if (!config.spacingContexts) return null;
  const columns = config.spacingContexts?.grid.columns ?? 12;
  const tabs = [
    { id: "spacing-scale", title: "Scale & Principles", content: <SpacingScaleAndPrinciples config={config} /> },
    { id: "spacing-grid", title: `${columns}-Col Grid`, content: <SpacingColumnGrid config={config} /> },
    { id: "spacing-rhythm", title: "Page Rhythm", content: <SpacingPageRhythm config={config} /> },
  ];
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <SubsectionTabs tabs={tabs} />
    </CollapsibleSection>
  );
}

// ⟦𓁞𓐜𓐩𓆤⟧ DividersSection :: auto-generated pointer for public function DividersSection
export function DividersSection({ number, id, title, desc }: SectionProps) {
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <DividerShowcase />
    </CollapsibleSection>
  );
}

// ⟦𓁬𓄓𓅭𓆫⟧ GlyphsSection :: auto-generated pointer for public function GlyphsSection
export function GlyphsSection({ number, id, title, desc, config }: SectionProps) {
  if (!config.glyphLanguage) return null;
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <GlyphShowcase glyphLanguage={config.glyphLanguage} />
    </CollapsibleSection>
  );
}

// ⟦𓐘𓂪𓂹𓍭⟧ CodeBlocksSection :: auto-generated pointer for public function CodeBlocksSection
export function CodeBlocksSection({ number, id, title, desc }: SectionProps) {
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <CodeBlockShowcase />
    </CollapsibleSection>
  );
}

// ⟦𓁦𓋆𓅰𓍁⟧ TerminalSection :: auto-generated pointer for public function TerminalSection
export function TerminalSection({ number, id, title, desc }: SectionProps) {
  return (
    <CollapsibleSection number={number} id={id} title={title} desc={desc} defaultOpen={true}>
      <TerminalShowcase />
    </CollapsibleSection>
  );
}
