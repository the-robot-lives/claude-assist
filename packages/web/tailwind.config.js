/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        void: "#09090B",
        canvas: "#0F0F14",
        surface: {
          DEFAULT: "#18181F",
          raised: "#22222E",
          active: "#2A2A38",
        },
        border: {
          subtle: "#2A2A3A",
          strong: "#3A3A4F",
        },
        glow: {
          DEFAULT: "#06B6D4",
          bright: "#22D3EE",
          dim: "color-mix(in srgb, #06B6D4 50%, transparent)",
          bg: "color-mix(in srgb, #06B6D4 8%, #18181F)",
        },
        text: {
          dim: "#5C5C72",
          muted: "#7A7A94",
          secondary: "#9898B0",
          primary: "#CDCDE0",
          bright: "#EDEDF4",
          max: "#FFFFFF",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "sans-serif"],
        mono: ["JetBrains Mono", "Fira Code", "SF Mono", "Menlo", "monospace"],
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
