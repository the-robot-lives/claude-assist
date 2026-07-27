import { Suspense } from "react";
import { GameBrowser } from "../components/GameBrowser";
import { loadCatalog } from "../lib/catalog";

export default async function Home() {
  const catalog = await loadCatalog();

  return (
    <main>
      <Suspense fallback={<div className="shell">Loading backlog...</div>}>
        <GameBrowser catalog={catalog} />
      </Suspense>
    </main>
  );
}
