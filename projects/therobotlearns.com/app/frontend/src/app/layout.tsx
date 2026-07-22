import type { Metadata } from "next";
import Script from "next/script";
import "./globals.css";
import { AuthProvider } from "@/context/auth";
import { OrgProvider } from "@/context/org";
import { Navbar } from "@/components/navbar";
import { AnalyticsProvider } from "@/components/analytics-provider";
import { CookieConsentProvider } from "@/components/cookie-consent";
import { OtelProvider } from "@/components/otel-provider";
import { loadConfig } from "@noizu/styleguide/css-gen";
import { Toaster } from "sonner";

export function generateMetadata(): Metadata {
  return {
    title: "The Robot Learns | AI learning workspace",
    description: "AI learning workspace",
  };
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const config = loadConfig();
  const t = config.toast;

  return (
    <html lang="en" data-design-theme={config.slug} suppressHydrationWarning>
      <Script src="/__env.js" strategy="beforeInteractive" />
      <Script id="color-mode-script" strategy="beforeInteractive">
        {`(function(){var s=localStorage.getItem('color-mode');var p=matchMedia('(prefers-color-scheme:dark)').matches;if(s==='dark'||(!s&&p))document.documentElement.classList.add('dark')})()`}
      </Script>
      <body>
        <OtelProvider>
          <AuthProvider>
            <OrgProvider>
              <CookieConsentProvider>
                <AnalyticsProvider>
                  <Navbar />
                  {children}
                </AnalyticsProvider>
              </CookieConsentProvider>
            </OrgProvider>
          </AuthProvider>
        </OtelProvider>
        <Toaster
          position={t?.position ?? "top-right"}
          expand={t?.expand ?? true}
          gap={t?.gap ?? 16}
          duration={t?.duration ?? 8000}
          visibleToasts={t?.["visible-toasts"] ?? 4}
          toastOptions={{
            unstyled: true,
            classNames: {
              toast: "toast",
              success: "success",
              error: "error",
              warning: "warning",
              info: "info",
            },
          }}
        />
      </body>
    </html>
  );
}
