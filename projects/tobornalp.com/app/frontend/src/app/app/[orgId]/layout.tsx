'use client';

import { OrgProvider } from '@/context/org';
import { OrgNav } from '@/components/pm/org-nav';
import { ReactNode } from 'react';

export default function OrgLayout({ children }: { children: ReactNode }) {
  return (
    <OrgProvider>
      <OrgNav>{children}</OrgNav>
    </OrgProvider>
  );
}
