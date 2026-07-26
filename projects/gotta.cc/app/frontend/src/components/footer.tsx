import Link from "next/link";

export function Footer() {
  return (
    <footer className="gc-footer">
      <div className="gc-wrap gc-foot-inner">
        <Link href="/" className="gc-wordmark">
          gotta<span className="gc-tld">.cc</span>
        </Link>
        <span className="gc-foot-tag">The web is big again.</span>
        <nav className="gc-foot-nav">
          <Link href="/about">About</Link>
          <Link href="/about#scoring">Rubric</Link>
          <Link href="/submit">Submit a site</Link>
          <a href="#">Privacy</a>
          <a href="#">Terms</a>
        </nav>
        <span className="gc-foot-copy">&copy; 2026 gotta.cc</span>
      </div>
    </footer>
  );
}
