import type { Metadata } from "next";
import "./globals.css";
import { AnalyticsProvider } from "@/components/analytics-provider";
import { CookieConsentProvider } from "@/components/cookie-consent";
import { OtelProvider } from "@/components/otel-provider";
import { loadConfig, loadAllBrandings } from "@noizu/styleguide/css-gen";
import { Toaster } from "sonner";

const SITE_TITLE = "Gotta.cc — The Yahoo Directory for the Post-Slop Web";
const SITE_DESC =
  "Browse curated categories. Read editorial summaries. Discover sites scored for originality, depth, and human authorship.";

export const metadata: Metadata = {
  title: SITE_TITLE,
  description:
    "An AI-curated website directory with browsable categories, editorial summaries, and quality scoring. Browse the web by topic, not by keyword.",
  openGraph: {
    title: SITE_TITLE,
    description: SITE_DESC,
    siteName: "gotta.cc",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: SITE_TITLE,
    description: SITE_DESC,
  },
  icons: {
    icon: "/favicon.svg",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const config = loadConfig();
  const allBrandings = loadAllBrandings();
  const fontUrls = [
    ...new Set(
      Object.values(allBrandings)
        .map((b) => b["font-url"])
        .filter(Boolean)
    ),
  ] as string[];
  const t = config.toast;

  return (
    <html lang="en" data-design-theme={config.slug} suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        {fontUrls.map((url) => (
          <link key={url} href={url} rel="stylesheet" />
        ))}
        <script src="/__env.js" />
      </head>
      <body>
        <OtelProvider>
          <CookieConsentProvider>
            <AnalyticsProvider>{children}</AnalyticsProvider>
          </CookieConsentProvider>
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
