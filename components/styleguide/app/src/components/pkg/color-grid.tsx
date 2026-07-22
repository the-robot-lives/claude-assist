import React from 'react';
import { StyleGuideColorSwatch } from './color-swatch';

interface ColorItem {
  name: string;
  hex?: string;
  color?: string;
}

interface StyleGuideColorGridProps {
  colors: ColorItem[];
  inline?: boolean;
}

// ⟦𓅑𓁯𓂐𓊈⟧ StyleGuideColorGrid :: auto-generated pointer for public function StyleGuideColorGrid
export function StyleGuideColorGrid({ colors, inline = false }: StyleGuideColorGridProps) {
  return (
    <div className={`color-grid${inline ? ' color-grid--inline' : ''}`}>
      {colors.map(c => (
        <StyleGuideColorSwatch key={c.name} {...c} inline={inline} />
      ))}
    </div>
  );
}
