"use client";

import { Suspense, useEffect, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { postAuthPath } from "@/lib/auth-flow";

function VerifyMagicLink() {
  const { loginWithMagicLink } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState("");
  const [verifying, setVerifying] = useState(true);

  useEffect(() => {
    const token = searchParams.get("token");
    if (!token) {
      setError("No token provided");
      setVerifying(false);
      return;
    }

    loginWithMagicLink(token)
      .then((user) => router.push(postAuthPath(user)))
      .catch(() => {
        setError("Invalid or expired magic link");
        setVerifying(false);
      });
  }, [searchParams, loginWithMagicLink, router]);

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Verify Magic Link</h1>
        {verifying && <p>Verifying your magic link...</p>}
        {error && (
          <>
            <p className="sg-error">{error}</p>
            <p>
              <Link href="/login">Back to login</Link>
            </p>
          </>
        )}
      </main>
    </div>
  );
}

// ⟦𓏈𓍿𓀥𓄜⟧ VerifyMagicLinkPage :: auto-generated pointer for public function VerifyMagicLinkPage
export default function VerifyMagicLinkPage() {
  return (
    <Suspense fallback={<div className="content"><main><p>Loading...</p></main></div>}>
      <VerifyMagicLink />
    </Suspense>
  );
}
