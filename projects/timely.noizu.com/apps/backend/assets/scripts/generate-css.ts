import { execSync } from "child_process";
import path from "path";

const TIMELY_ROOT = path.resolve(__dirname, "../..");
const PKG_DIR = path.join(TIMELY_ROOT, "node_modules", "@noizu", "styleguide");

execSync("npx tsx src/generate.ts", {
  cwd: PKG_DIR,
  env: {
    ...process.env,
    STYLEGUIDE_CONFIG_ROOT: path.join(TIMELY_ROOT, "src", "config"),
    STYLEGUIDE_OUTPUT: path.join(TIMELY_ROOT, "src", "app", "design-system.generated.css"),
    STYLEGUIDE_THEME_DIR: path.join(TIMELY_ROOT, "public", "themes"),
  },
  stdio: "inherit",
});
