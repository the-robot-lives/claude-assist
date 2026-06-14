import type { Metadata } from "next";
import "./globals.css";
import { loadConfig, listThemes } from "@noizu/styleguide/css-gen";
import { loadAllBrandings } from "@noizu/styleguide/css-gen";
import { ThemeCSS } from "@noizu/styleguide/providers";

export const metadata: Metadata = {
  title: "Style Guide Viewer",
  description: "Interactive design system viewer",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const config = loadConfig();
  const themes = listThemes();
  const themeSlugs = themes.map((t) => t.slug);
  const allBrandings = loadAllBrandings();
  const fontUrls = [...new Set(
    Object.values(allBrandings).map((b: any) => b["font-url"]).filter(Boolean)
  )] as string[];

  return (
    <html lang="en" data-design-theme={config.slug} suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        {fontUrls.map((url) => (
          <link key={url} href={url} rel="stylesheet" />
        ))}
        <script dangerouslySetInnerHTML={{ __html: `(function(){var s=localStorage.getItem('color-mode');var p=matchMedia('(prefers-color-scheme:dark)').matches;if(s==='dark'||(!s&&p))document.documentElement.classList.add('dark');var v=${JSON.stringify(themeSlugs)};var t=localStorage.getItem('sg-theme');if(t&&v.indexOf(t)!==-1)document.documentElement.setAttribute('data-design-theme',t);else if(t)localStorage.removeItem('sg-theme')})()` }} />
      </head>
      <body>
        <ThemeCSS themeSlugs={themeSlugs} defaultTheme={config.slug} />
        {children}
      </body>
    </html>
  );
}
