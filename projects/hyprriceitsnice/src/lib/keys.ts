import type { KeyId } from "./bindings";

/** Map browser KeyboardEvent → our KeyId set (best-effort for practice mode). */
export function eventToKeyIds(e: KeyboardEvent): KeyId[] {
  const ids: KeyId[] = [];
  if (e.metaKey || e.getModifierState?.("OS") || e.getModifierState?.("Super")) {
    ids.push("super");
  }
  // On many Linux browsers Super arrives as Meta; also track Ctrl/Alt/Shift.
  if (e.ctrlKey) ids.push("ctrl");
  if (e.altKey) ids.push("alt");
  if (e.shiftKey) ids.push("shift");

  const k = e.key;
  const code = e.code;

  const map: Record<string, KeyId> = {
    Enter: "return",
    " ": "space",
    Space: "space",
    Tab: "tab",
    Escape: "escape",
    PrintScreen: "print",
    ArrowLeft: "left",
    ArrowRight: "right",
    ArrowUp: "up",
    ArrowDown: "down",
    a: "a",
    A: "a",
    b: "b",
    B: "b",
    c: "c",
    C: "c",
    e: "e",
    E: "e",
    f: "f",
    F: "f",
    h: "h",
    H: "h",
    j: "j",
    J: "j",
    k: "k",
    K: "k",
    l: "l",
    L: "l",
    m: "m",
    M: "m",
    p: "p",
    P: "p",
    q: "q",
    Q: "q",
    s: "s",
    S: "s",
    t: "t",
    T: "t",
    v: "v",
    V: "v",
    w: "w",
    W: "w",
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "6",
    "7": "7",
    "8": "8",
    "9": "9",
    "0": "0",
  };

  if (map[k]) ids.push(map[k]);
  else if (map[code.replace("Key", "").replace("Digit", "")]) {
    // fallthrough unused — code paths covered by key above
  }

  // Right Control (when distinguishable)
  if (code === "ControlRight") {
    if (!ids.includes("rctrl")) ids.push("rctrl");
  }

  return [...new Set(ids)];
}

export function setsEqual(a: KeyId[], b: KeyId[]): boolean {
  if (a.length !== b.length) return false;
  const sa = [...a].sort();
  const sb = [...b].sort();
  return sa.every((v, i) => v === sb[i]);
}

/** Binding matches if every keyId in the binding is currently held, and counts align for simple combos. */
export function bindingMatchesHeld(held: KeyId[], bindingKeys: KeyId[]): boolean {
  if (bindingKeys.length === 0) return false;
  // Normalize: if binding wants rctrl, allow ctrl as partial match only when rctrl held
  const heldSet = new Set(held);
  return bindingKeys.every((k) => {
    if (k === "rctrl") return heldSet.has("rctrl") || heldSet.has("ctrl");
    if (k === "ctrl") return heldSet.has("ctrl") || heldSet.has("rctrl");
    return heldSet.has(k);
  }) && held.length >= bindingKeys.length - 0;
}
