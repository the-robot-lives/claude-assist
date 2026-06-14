// Auto-generated from YAML jsx-snippets — do not edit manually
"use client";

import { useState } from "react";

// @counter-demo
// Counter Demo: Simple counter
// A basic counter component to verify JSX snippet generation works.
// depends: demo-imports
export function CounterDemo() {
  const [count, setCount] = useState(0);
  return (
    <button className="btn btn-sm" onClick={() => setCount((c) => c + 1)}>
      Count: {count}
    </button>
  );
}
