import type { Metadata } from "next";
import { Plus_Jakarta_Sans, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/context/auth";
import { OrgProvider } from "@/context/org";
import { Navbar } from "@/components/navbar";
import { AnalyticsProvider } from "@/components/analytics-provider";
import { CookieConsentProvider } from "@/components/cookie-consent";
import { OtelProvider } from "@/components/otel-provider";
import { loadConfig, loadAllBrandings } from "@noizu/styleguide/css-gen";
import { Toaster } from "sonner";

const jakartaSans = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export function generateMetadata(): Metadata {
  const config = loadConfig();
  const title = config.title ?? "CodeFresh — Behavioral Testing for AI Agents";
  const description =
    config.description ??
    "Script conversations. Run evaluations. Catch agent regressions before your users do. The testing framework AI engineers actually need.";
  return {
    title,
    description,
    openGraph: {
      title,
      description,
      siteName: "codefre.sh",
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}

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
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){var s=localStorage.getItem('color-mode');var p=matchMedia('(prefers-color-scheme:dark)').matches;if(s==='dark'||(!s&&p))document.documentElement.classList.add('dark')})()`,
          }}
        />
      </head>
      <body className={`${jakartaSans.variable} ${jetbrainsMono.variable} antialiased`}>
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
