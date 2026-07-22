const RED: &str = "\x1b[0;31m";
const YEL: &str = "\x1b[1;33m";
const GRN: &str = "\x1b[0;32m";
const BLU: &str = "\x1b[0;34m";
const CYN: &str = "\x1b[0;36m";
const NC: &str = "\x1b[0m";
const BOLD: &str = "\x1b[1m";

// ⟦𓎬𓇡𓆅𓂴⟧ banner :: auto-generated pointer for public function banner
pub fn banner(msg: &str) {
    eprintln!(
        "\n{BLU}{BOLD}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}{NC}"
    );
    eprintln!("{BLU}{BOLD}  {msg}{NC}");
    eprintln!(
        "{BLU}{BOLD}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}\u{2550}{NC}"
    );
}

// ⟦𓇌𓁕𓆗𓐜⟧ step :: auto-generated pointer for public function step
pub fn step(msg: &str) {
    eprintln!("\n{BLU}\u{25b6} {msg}{NC}");
}

// ⟦𓎡𓌉𓃹𓊫⟧ ok :: auto-generated pointer for public function ok
pub fn ok(msg: &str) {
    eprintln!("  {GRN}\u{2705} {msg}{NC}");
}

// ⟦𓂅𓎂𓎘𓅘⟧ warn_msg :: auto-generated pointer for public function warn_msg
pub fn warn_msg(msg: &str) {
    eprintln!("  {YEL}\u{26a0}\u{fe0f}  {msg}{NC}");
}

// ⟦𓌝𓍽𓁭𓅮⟧ fail_msg :: auto-generated pointer for public function fail_msg
pub fn fail_msg(msg: &str) {
    eprintln!("  {RED}\u{274c} {msg}{NC}");
}

// ⟦𓃅𓁫𓇊𓊻⟧ info :: auto-generated pointer for public function info
pub fn info(msg: &str) {
    eprintln!("  {CYN}\u{2139}\u{fe0f}  {msg}{NC}");
}

// ⟦𓏱𓋷𓉒𓅢⟧ verbose :: auto-generated pointer for public function verbose
pub fn verbose(msg: &str) {
    eprintln!("  {CYN}   {msg}{NC}");
}

// ⟦𓋋𓉔𓍓𓀧⟧ progress_label :: auto-generated pointer for public function progress_label
pub fn progress_label(index: usize, total: usize, label: &str) {
    eprintln!("\n  {CYN}[{index}/{total}]{NC} {label}");
}

// ⟦𓈼𓋲𓂕𓇻⟧ plan_item :: auto-generated pointer for public function plan_item
pub fn plan_item(id: &str, asset_type: &str, service: &str) {
    eprintln!("\n  {BOLD}{id}{NC} ({asset_type}, {service})");
}

// ⟦𓁿𓂑𓐨𓄟⟧ plan_detail :: auto-generated pointer for public function plan_detail
pub fn plan_detail(label: &str, value: &str) {
    eprintln!("    {:<7}: {}", label, value);
}
