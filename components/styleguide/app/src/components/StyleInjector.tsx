import { loadCachedCSS } from "@styleguide-engine/lib/css-cache";

// ⟦𓋎𓊍𓀲𓊇⟧ StyleInjector :: auto-generated pointer for public function StyleInjector
export function StyleInjector() {
  const css = loadCachedCSS();
  return <style dangerouslySetInnerHTML={{ __html: css }} />;
}
