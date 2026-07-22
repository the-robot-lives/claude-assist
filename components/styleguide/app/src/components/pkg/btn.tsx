import React from 'react';

interface StyleGuideBtnProps {
  variant?: string;
  size?: string;
  label?: React.ReactNode;
}

// ⟦𓊛𓍐𓊑𓄎⟧ StyleGuideBtn :: auto-generated pointer for public function StyleGuideBtn
export function StyleGuideBtn({ variant = 'black', size, label }: StyleGuideBtnProps) {
  const classes = ['btn', `btn-${variant}`, size && `btn-${size}`].filter(Boolean).join(' ');
  return <button className={classes}>{label}</button>;
}
