export type CategoryId =
  | "launch"
  | "windows"
  | "focus"
  | "workspaces"
  | "scratchpad"
  | "ai"
  | "clipboard"
  | "media"
  | "extra"
  | "system";

export type KeyId =
  | "super"
  | "shift"
  | "ctrl"
  | "alt"
  | "rctrl"
  | "return"
  | "space"
  | "tab"
  | "print"
  | "escape"
  | "f"
  | "e"
  | "b"
  | "m"
  | "v"
  | "p"
  | "t"
  | "a"
  | "s"
  | "q"
  | "w"
  | "h"
  | "j"
  | "k"
  | "l"
  | "c"
  | "1"
  | "2"
  | "3"
  | "4"
  | "5"
  | "6"
  | "7"
  | "8"
  | "9"
  | "0"
  | "left"
  | "right"
  | "up"
  | "down"
  | "scroll"
  | "lmb"
  | "rmb"
  | "volup"
  | "voldown"
  | "mute"
  | "micmute"
  | "brightup"
  | "brightdown"
  | "play"
  | "next"
  | "prev";

export interface Binding {
  id: string;
  keys: string[];
  keyIds: KeyId[];
  action: string;
  category: CategoryId;
  notes?: string;
  tags?: string[];
}

export interface Category {
  id: CategoryId;
  label: string;
  emoji: string;
  description: string;
}

export const CATEGORIES: Category[] = [
  { id: "launch", label: "Launch", emoji: "🚀", description: "Apps & menus" },
  { id: "windows", label: "Windows", emoji: "🪟", description: "Float, pin, kill, split" },
  { id: "focus", label: "Focus / Move", emoji: "🎯", description: "Vim + arrows + resize" },
  { id: "workspaces", label: "Workspaces", emoji: "🗂", description: "Jump, move, swipe" },
  { id: "scratchpad", label: "Scratchpad", emoji: "📎", description: "special:scratchpad" },
  { id: "ai", label: "AI Workspace", emoji: "🤖", description: "special:ai floating layout" },
  { id: "clipboard", label: "Clip / Shot", emoji: "📋", description: "cliphist + grim/slurp" },
  { id: "media", label: "Media / HW", emoji: "🔊", description: "Volume, brightness, player" },
  { id: "extra", label: "Extra UI", emoji: "✨", description: "Waybar, snapshots, foot+tmux" },
  { id: "system", label: "System", emoji: "⚙️", description: "Notes & gotchas" },
];

export const BINDINGS: Binding[] = [
  // Launch
  {
    id: "term",
    keys: ["SUPER", "Return"],
    keyIds: ["super", "return"],
    action: "Open terminal (ghostty)",
    category: "launch",
    tags: ["terminal", "ghostty"],
  },
  {
    id: "menu-alt",
    keys: ["ALT", "Space"],
    keyIds: ["alt", "space"],
    action: "App launcher (wofi) — Spotlight-style",
    category: "launch",
    tags: ["wofi", "menu"],
  },
  {
    id: "menu-super",
    keys: ["SUPER", "Space"],
    keyIds: ["super", "space"],
    action: "App launcher (wofi)",
    category: "launch",
    notes: "Also declared as terminal earlier in conf; later bind wins → menu.",
    tags: ["wofi", "menu"],
  },
  {
    id: "browser",
    keys: ["SUPER", "B"],
    keyIds: ["super", "b"],
    action: "Browser (chromium)",
    category: "launch",
    tags: ["chromium"],
  },
  {
    id: "files",
    keys: ["SUPER", "E"],
    keyIds: ["super", "e"],
    action: "File manager (dolphin)",
    category: "launch",
    tags: ["dolphin"],
  },
  {
    id: "nomachine",
    keys: ["SUPER", "M"],
    keyIds: ["super", "m"],
    action: "NoMachine player",
    category: "launch",
    tags: ["nxplayer"],
  },

  // Windows
  {
    id: "kill",
    keys: ["SUPER", "RCTRL", "Q"],
    keyIds: ["super", "rctrl", "q"],
    action: "Kill active window",
    category: "windows",
  },
  {
    id: "float",
    keys: ["SUPER", "SHIFT", "V"],
    keyIds: ["super", "shift", "v"],
    action: "Toggle floating",
    category: "windows",
  },
  {
    id: "fullscreen",
    keys: ["SUPER", "F"],
    keyIds: ["super", "f"],
    action: "Fullscreen",
    category: "windows",
  },
  {
    id: "pseudo",
    keys: ["SUPER", "P"],
    keyIds: ["super", "p"],
    action: "Pseudo-tile (dwindle)",
    category: "windows",
  },
  {
    id: "togglesplit",
    keys: ["SUPER", "T"],
    keyIds: ["super", "t"],
    action: "Toggle split (dwindle)",
    category: "windows",
  },
  {
    id: "pin",
    keys: ["CTRL", "ALT", "P"],
    keyIds: ["ctrl", "alt", "p"],
    action: "Float + pin (sticky across workspaces)",
    category: "windows",
    tags: ["pin", "sticky"],
  },
  {
    id: "move-mouse",
    keys: ["SUPER", "LMB drag"],
    keyIds: ["super", "lmb"],
    action: "Move window with mouse",
    category: "windows",
  },
  {
    id: "resize-mouse",
    keys: ["SUPER", "RMB drag"],
    keyIds: ["super", "rmb"],
    action: "Resize window with mouse",
    category: "windows",
  },

  // Focus
  {
    id: "focus-h",
    keys: ["SUPER", "H"],
    keyIds: ["super", "h"],
    action: "Focus left",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "focus-j",
    keys: ["SUPER", "J"],
    keyIds: ["super", "j"],
    action: "Focus down",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "focus-k",
    keys: ["SUPER", "K"],
    keyIds: ["super", "k"],
    action: "Focus up",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "focus-l",
    keys: ["SUPER", "L"],
    keyIds: ["super", "l"],
    action: "Focus right",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "focus-left",
    keys: ["SUPER", "←"],
    keyIds: ["super", "left"],
    action: "Focus left (arrow)",
    category: "focus",
  },
  {
    id: "focus-right",
    keys: ["SUPER", "→"],
    keyIds: ["super", "right"],
    action: "Focus right (arrow)",
    category: "focus",
  },
  {
    id: "focus-up",
    keys: ["SUPER", "↑"],
    keyIds: ["super", "up"],
    action: "Focus up (arrow)",
    category: "focus",
  },
  {
    id: "focus-down",
    keys: ["SUPER", "↓"],
    keyIds: ["super", "down"],
    action: "Focus down (arrow)",
    category: "focus",
  },
  {
    id: "movewin-h",
    keys: ["SUPER", "SHIFT", "H"],
    keyIds: ["super", "shift", "h"],
    action: "Move window left",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "movewin-j",
    keys: ["SUPER", "SHIFT", "J"],
    keyIds: ["super", "shift", "j"],
    action: "Move window down",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "movewin-k",
    keys: ["SUPER", "SHIFT", "K"],
    keyIds: ["super", "shift", "k"],
    action: "Move window up",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "movewin-l",
    keys: ["SUPER", "SHIFT", "L"],
    keyIds: ["super", "shift", "l"],
    action: "Move window right",
    category: "focus",
    tags: ["vim"],
  },
  {
    id: "resize-h",
    keys: ["SUPER", "CTRL", "H"],
    keyIds: ["super", "ctrl", "h"],
    action: "Resize −40px width",
    category: "focus",
  },
  {
    id: "resize-l",
    keys: ["SUPER", "CTRL", "L"],
    keyIds: ["super", "ctrl", "l"],
    action: "Resize +40px width",
    category: "focus",
  },
  {
    id: "resize-k",
    keys: ["SUPER", "CTRL", "K"],
    keyIds: ["super", "ctrl", "k"],
    action: "Resize −40px height",
    category: "focus",
  },
  {
    id: "resize-j",
    keys: ["SUPER", "CTRL", "J"],
    keyIds: ["super", "ctrl", "j"],
    action: "Resize +40px height",
    category: "focus",
  },

  // Workspaces
  ...([1, 2, 3, 4, 5, 6, 7, 8, 9] as const).flatMap((n): Binding[] => {
    const digit = String(n) as KeyId;
    return [
      {
        id: `ws-${n}`,
        keys: ["SUPER", String(n)],
        keyIds: ["super", digit],
        action: `Go to workspace ${n}${n <= 5 ? " (HDMI)" : " (laptop)"}`,
        category: "workspaces",
        tags: [n <= 5 ? "hdmi" : "laptop"],
      },
      {
        id: `movews-${n}`,
        keys: ["SUPER", "SHIFT", String(n)],
        keyIds: ["super", "shift", digit],
        action: `Move window → workspace ${n}`,
        category: "workspaces",
      },
    ];
  }),
  {
    id: "ws-10",
    keys: ["SUPER", "0"],
    keyIds: ["super", "0"],
    action: "Go to workspace 10",
    category: "workspaces",
  },
  {
    id: "movews-10",
    keys: ["SUPER", "SHIFT", "0"],
    keyIds: ["super", "shift", "0"],
    action: "Move window → workspace 10",
    category: "workspaces",
  },
  {
    id: "ws-next",
    keys: ["SUPER", "Tab"],
    keyIds: ["super", "tab"],
    action: "Next workspace",
    category: "workspaces",
  },
  {
    id: "ws-prev",
    keys: ["SUPER", "SHIFT", "Tab"],
    keyIds: ["super", "shift", "tab"],
    action: "Previous workspace",
    category: "workspaces",
  },
  {
    id: "ws-scroll",
    keys: ["SUPER", "Scroll"],
    keyIds: ["super", "scroll"],
    action: "Cycle workspaces (mouse wheel)",
    category: "workspaces",
  },
  {
    id: "ws-swipe",
    keys: ["3-finger swipe"],
    keyIds: [],
    action: "Swipe workspaces (touchpad)",
    category: "workspaces",
    notes: "Horizontal 3-finger gesture",
  },

  // Scratchpad
  {
    id: "scratch-toggle",
    keys: ["SUPER", "S"],
    keyIds: ["super", "s"],
    action: "Toggle special:scratchpad",
    category: "scratchpad",
  },
  {
    id: "scratch-send",
    keys: ["SUPER", "SHIFT", "S"],
    keyIds: ["super", "shift", "s"],
    action: "Send window → scratchpad",
    category: "scratchpad",
  },

  // AI
  {
    id: "ai-toggle",
    keys: ["SUPER", "A"],
    keyIds: ["super", "a"],
    action: "Toggle AI workspace (special:ai)",
    category: "ai",
  },
  {
    id: "ai-launch",
    keys: ["SUPER", "SHIFT", "A"],
    keyIds: ["super", "shift", "a"],
    action: "Launch AI layout (Chrome + Obsidian + term)",
    category: "ai",
    notes: "Runs ~/.config/hypr/bin/ai-workspace-launch",
    tags: ["script"],
  },
  {
    id: "ai-move-in",
    keys: ["SUPER", "ALT", "C"],
    keyIds: ["super", "alt", "c"],
    action: "Move focused → AI workspace (silent)",
    category: "ai",
  },
  {
    id: "ai-move-out",
    keys: ["SUPER", "ALT", "M"],
    keyIds: ["super", "alt", "m"],
    action: "Move from special → current workspace",
    category: "ai",
  },

  // Clipboard / screenshots
  {
    id: "cliphist",
    keys: ["SUPER", "V"],
    keyIds: ["super", "v"],
    action: "Clipboard history (cliphist → wofi)",
    category: "clipboard",
    tags: ["cliphist"],
  },
  {
    id: "shot-region",
    keys: ["Print"],
    keyIds: ["print"],
    action: "Region screenshot → clipboard",
    category: "clipboard",
    tags: ["grim", "slurp"],
  },
  {
    id: "shot-full",
    keys: ["SUPER", "Print"],
    keyIds: ["super", "print"],
    action: "Fullscreen screenshot → clipboard",
    category: "clipboard",
    tags: ["grim"],
  },
  {
    id: "shot-file",
    keys: ["SUPER", "SHIFT", "Print"],
    keyIds: ["super", "shift", "print"],
    action: "Region screenshot → ~/Pictures/…",
    category: "clipboard",
    tags: ["grim", "slurp"],
  },

  // Media
  {
    id: "vol-up",
    keys: ["Vol ↑"],
    keyIds: ["volup"],
    action: "Volume +5% (cap 100%)",
    category: "media",
  },
  {
    id: "vol-down",
    keys: ["Vol ↓"],
    keyIds: ["voldown"],
    action: "Volume −5%",
    category: "media",
  },
  {
    id: "mute",
    keys: ["Mute"],
    keyIds: ["mute"],
    action: "Toggle sink mute",
    category: "media",
  },
  {
    id: "mic-mute",
    keys: ["Mic mute"],
    keyIds: ["micmute"],
    action: "Toggle source mute",
    category: "media",
  },
  {
    id: "bright-up",
    keys: ["Bright ↑"],
    keyIds: ["brightup"],
    action: "Brightness +5%",
    category: "media",
  },
  {
    id: "bright-down",
    keys: ["Bright ↓"],
    keyIds: ["brightdown"],
    action: "Brightness −5%",
    category: "media",
  },
  {
    id: "play",
    keys: ["Play/Pause"],
    keyIds: ["play"],
    action: "playerctl play-pause",
    category: "media",
  },
  {
    id: "next",
    keys: ["Next"],
    keyIds: ["next"],
    action: "playerctl next",
    category: "media",
  },
  {
    id: "prev",
    keys: ["Prev"],
    keyIds: ["prev"],
    action: "playerctl previous",
    category: "media",
  },

  // Extra
  {
    id: "waybar-notch",
    keys: ["SUPER", "ALT", "W"],
    keyIds: ["super", "alt", "w"],
    action: "Toggle waybar notch-dock (profile 6 only)",
    category: "extra",
  },
  {
    id: "snapshots",
    keys: ["SUPER", "CTRL", "5"],
    keyIds: ["super", "ctrl", "5"],
    action: "Desktop snapshots overview",
    category: "extra",
    notes: "~/.config/hypr/bin/desktop-snapshots overview",
  },
  {
    id: "foot-big",
    keys: ["SUPER", "SHIFT", "Return"],
    keyIds: ["super", "shift", "return"],
    action: "foot-big on HDMI (tmux session main)",
    category: "extra",
    notes: "70%×60% float on external monitor",
    tags: ["foot", "tmux"],
  },
  {
    id: "foot-pad",
    keys: ["SUPER", "ALT", "Return"],
    keyIds: ["super", "alt", "return"],
    action: "foot-pad on laptop (tmux session main)",
    category: "extra",
    notes: "90%×85% float on eDP-1",
    tags: ["foot", "tmux"],
  },

  // System notes as pseudo-bindings
  {
    id: "no-exit",
    keys: ["SUPER", "SHIFT", "Q"],
    keyIds: ["super", "shift", "q"],
    action: "Exit Hyprland — DISABLED on purpose",
    category: "system",
    notes: "Commented out in hyprland.conf to avoid accidents",
  },
];

export const MONITORS = [
  {
    id: "hdmi",
    name: "HDMI-A-1",
    label: "MSI MAG 273Q",
    mode: "2560×1440@120",
    scale: "1",
    role: "Primary · top stand",
    workspaces: "1–5",
  },
  {
    id: "edp",
    name: "eDP-1",
    label: "Samsung OLED",
    mode: "2880×1620@120",
    scale: "1.5 → 1920×1080 logical",
    role: "Laptop · centered under MSI",
    workspaces: "6–9",
  },
] as const;

export const APPS = [
  { key: "$terminal", value: "ghostty" },
  { key: "$browser", value: "chromium" },
  { key: "$fileManager", value: "dolphin" },
  { key: "$menu", value: "wofi --show drun" },
] as const;

export const AI_LAYOUT = [
  { app: "Chrome / Chromium", place: "Left 58% × 72%" },
  { app: "Obsidian", place: "Right 40% × 97%" },
  { app: "foot / kitty", place: "Under chrome 58% × 22%" },
] as const;

export const AUTOSTART = [
  "waybar",
  "swaync",
  "polkit-gnome",
  "wl-paste → cliphist (text + image)",
  "desktop-snapshots daemon",
  "foot --server",
] as const;

export const RICE = {
  layout: "dwindle (smart_split, preserve_split, pseudotile)",
  gaps: "in 3 · out 6",
  border: "1px · rounding 8",
  activeBorder: "#7aa2f7 → #bb9af7 (45°)",
  theme: "Tokyo Night-ish",
  blur: "on · size 8 · 4 passes",
  vrr: "off",
} as const;

export const WS_TITLES: Record<string, string> = {
  "1": "osx",
  "2": "win",
  "3": "dev",
  "4": "web",
  "5": "ai",
};

export function formatKeys(keys: string[]): string {
  return keys.join(" + ");
}

export function bindingMatchesQuery(b: Binding, q: string): boolean {
  if (!q) return true;
  const hay = [
    b.action,
    ...b.keys,
    b.category,
    b.notes ?? "",
    ...(b.tags ?? []),
  ]
    .join(" ")
    .toLowerCase();
  return q
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .every((token) => hay.includes(token));
}
