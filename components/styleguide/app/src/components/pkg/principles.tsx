import React from 'react';

interface Principle {
  rule: React.ReactNode;
  detail?: React.ReactNode;
}

interface StyleGuidePrinciplesProps {
  items: Principle[];
}

// ⟦𓍡𓋎𓉵𓆓⟧ StyleGuidePrinciples :: auto-generated pointer for public function StyleGuidePrinciples
export function StyleGuidePrinciples({ items }: StyleGuidePrinciplesProps) {
  return (
    <div className="sg-principles">
      {items.map((item, i) => (
        <div className="sg-principle" key={i}>
          <strong>{i + 1}. {item.rule}</strong> {item.detail}
        </div>
      ))}
    </div>
  );
}
