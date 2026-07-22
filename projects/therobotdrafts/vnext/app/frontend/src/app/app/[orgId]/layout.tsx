'use client';

import { OrgProvider } from '@/context/org';
import { ReactNode } from 'react';
import { useAuth } from '@/context/auth';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { userNeedsProfile, userPendingApproval } from '@/lib/auth-flow';

export default function OrgLayout({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && userNeedsProfile(user)) router.push('/complete-registration');
    if (!loading && userPendingApproval(user)) router.push('/pending-approval');
  }, [loading, router, user]);

  return <OrgProvider>{children}</OrgProvider>;
}
