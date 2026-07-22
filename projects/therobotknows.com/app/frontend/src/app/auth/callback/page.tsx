"use client";

import { Suspense, useEffect } from "react";
import { useRouter } from "next/navigation";

/** Legacy path — SSO now lands on /auth/sso-callback. */
function Redirect() {
  const router = useRouter();
  useEffect(() => {
    const qs = typeof window !== "undefined" ? window.location.search : "";
    router.replace(`/auth/sso-callback${qs}`);
  }, [router]);
  return null;
}

export default function LegacyAuthCallback() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-page">
      <Suspense>
        <Redirect />
      </Suspense>
    </div>
  );
}
