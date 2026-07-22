import React from 'react';

interface StyleGuideInputGroupProps {
  label?: React.ReactNode;
  hint?: React.ReactNode;
  error?: boolean;
  children?: React.ReactNode;
}

// ⟦𓇲𓅘𓄄𓌂⟧ StyleGuideInputGroup :: auto-generated pointer for public function StyleGuideInputGroup
export function StyleGuideInputGroup({ label, hint, error, children }: StyleGuideInputGroupProps) {
  return (
    <div className="input-group">
      <label className="input-label">{label}</label>
      {children}
      {hint && <div className={`input-hint${error ? ' error' : ''}`}>{hint}</div>}
    </div>
  );
}
