mod attachments;
mod dag;
mod eval;
mod fim;
mod output;
mod pipeline;
mod prep;
mod providers;
mod refine;
mod renderers;
mod schema;
mod ui;
mod validate;

use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::process::Command;

use clap::Parser;
use dialoguer::MultiSelect;

use pipeline::PipelineConfig;
use schema::{parse_prompt_file, ParsedPrompt, Quality};

#[derive(Parser, Debug)]
#[command(
    name = "generate-media-prompt",
    about = "Generate media assets from .media.prompt YAML files",
    version
)]
struct Cli {
    /// Prompt files or directories to process. Directories are processed without selection.
    inputs: Vec<PathBuf>,

    /// Recursively scan a directory and choose which prompt files to process
    #[arg(short = 'r', long = "recursive", value_name = "DIR")]
    recursive_dirs: Vec<PathBuf>,

    /// Number of zellij panes to use for selected prompt batches
    #[arg(short = 'j', long = "jobs", default_value_t = 1)]
    jobs: usize,

    /// Number of candidates to generate; best is vision-selected
    #[arg(short = 'n', default_value = "1")]
    variants: usize,

    /// Show generation plan without making API calls
    #[arg(long)]
    dry_run: bool,

    /// Overwrite existing output files
    #[arg(long)]
    force: bool,

    /// Interactive refinement loop after generation
    #[arg(long)]
    refine: bool,

    /// Override generation model
    #[arg(long)]
    model: Option<String>,

    /// Show detailed output
    #[arg(long)]
    verbose: bool,

    /// Quality tier override: low|medium|high (default: per-prompt or medium)
    #[arg(long, value_name = "TIER")]
    quality: Option<String>,

    /// Pin provider service (skips auto-selection)
    #[arg(long, value_name = "SVC")]
    service: Option<String>,

    /// Skip eval grading and provider fallback
    #[arg(long)]
    no_eval: bool,

    /// Skip LLM prompt preparation (send raw prompt text to provider)
    #[arg(long)]
    no_prep: bool,

    /// Disable FIM solution injection into the prompt-prep agent's guidance
    #[arg(long)]
    no_fim: bool,

    /// Override eval endpoint base URL
    #[arg(long, value_name = "URL")]
    eval_url: Option<String>,

    /// Override eval model ID
    #[arg(long, value_name = "ID")]
    eval_model: Option<String>,
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    let cli = Cli::parse();

    if cli.variants < 1 {
        color_eyre::eyre::bail!("Variant count must be at least 1");
    }
    if cli.jobs < 1 {
        color_eyre::eyre::bail!("Job count must be at least 1");
    }

    // Parse quality override
    let quality_override: Option<Quality> = if let Some(ref q) = cli.quality {
        match q.parse::<Quality>() {
            Ok(v) => Some(v),
            Err(e) => {
                color_eyre::eyre::bail!("--quality: {}", e);
            }
        }
    } else {
        None
    };

    // Load .envrc.k8.dc for API keys (GEMINI, SUNO, OPENAI, ELEVENLABS, DASHSCOPE)
    try_load_envrc();

    // Expand inputs: plain directories become all *.prompt files within. Directories passed
    // via -r/--recursive are shown in an interactive multi-select first.
    let mut prompt_files: Vec<PathBuf> = Vec::new();
    for input in &cli.inputs {
        if input.is_dir() {
            let mut found: Vec<PathBuf> = Vec::new();
            collect_prompt_files(input, &mut found);
            found.sort();
            if found.is_empty() {
                ui::warn_msg(&format!(
                    "No *.prompt files found in directory: {}",
                    input.display()
                ));
            }
            prompt_files.extend(found);
        } else if input.is_file() {
            prompt_files.push(input.clone());
        } else {
            ui::fail_msg(&format!("File or directory not found: {}", input.display()));
        }
    }

    let mut selectable_prompt_files: Vec<PathBuf> = Vec::new();
    for dir in &cli.recursive_dirs {
        if dir.is_dir() {
            let mut found: Vec<PathBuf> = Vec::new();
            collect_prompt_files(dir, &mut found);
            found.sort();
            if found.is_empty() {
                ui::warn_msg(&format!(
                    "No *.prompt files found in directory: {}",
                    dir.display()
                ));
            }
            selectable_prompt_files.extend(found);
        } else if dir.exists() {
            ui::fail_msg(&format!(
                "Recursive input is not a directory: {}",
                dir.display()
            ));
        } else {
            ui::fail_msg(&format!("Directory not found: {}", dir.display()));
        }
    }

    if !selectable_prompt_files.is_empty() {
        let selected = select_prompt_files(selectable_prompt_files, &cli.recursive_dirs)?;
        prompt_files.extend(selected);
    }

    prompt_files = normalize_prompt_files(prompt_files);

    if prompt_files.is_empty() {
        color_eyre::eyre::bail!("No valid .prompt files to process");
    }

    if cli.jobs > 1 {
        launch_zellij_batches(&prompt_files, &cli)?;
        return Ok(());
    }

    // Parse all prompt files
    ui::step("Loading prompt files");
    let mut prompts = Vec::new();
    for path in &prompt_files {
        let p = parse_prompt_file(path)?;
        if cli.verbose {
            let svc = p.meta.service.as_deref().unwrap_or("auto");
            ui::verbose(&format!(
                "Loaded: {} ({:?}, service={}, quality={}, schema=v{})",
                path.display(),
                p.meta.asset_type,
                svc,
                p.meta.quality.as_str(),
                p.meta.schema_version
            ));
        }
        prompts.push(p);
    }
    ui::ok(&format!("Loaded {} prompt file(s)", prompts.len()));

    // Run pipeline
    // FIM solution injection into the prep agent is on by default; disable via --no-fim
    // or MEDIA_FIM_INJECT=0.
    let fim_enabled = !cli.no_fim && std::env::var("MEDIA_FIM_INJECT").ok().as_deref() != Some("0");

    let config = PipelineConfig {
        variant_count: cli.variants,
        dry_run: cli.dry_run,
        force: cli.force,
        model_override: cli.model,
        verbose: cli.verbose,
        refine: cli.refine,
        quality_override,
        service_override: cli.service,
        no_eval: cli.no_eval,
        no_prep: cli.no_prep,
        fim_enabled,
        eval_url: cli.eval_url,
        eval_model: cli.eval_model,
    };

    pipeline::run_generation(prompts, &config).await?;

    Ok(())
}

fn try_load_envrc() {
    let candidates = [
        std::env::var("INFRA_ROOT")
            .ok()
            .map(|r| PathBuf::from(r).join(".envrc.k8.dc")),
        std::env::var("HOME")
            .ok()
            .map(|h| PathBuf::from(h).join(".envrc.k8.dc")),
    ];

    for candidate in candidates.into_iter().flatten() {
        if candidate.is_file() {
            if let Ok(content) = std::fs::read_to_string(&candidate) {
                for line in content.lines() {
                    let line = line.trim();
                    if let Some(rest) = line.strip_prefix("export ") {
                        if let Some((key, val)) = rest.split_once('=') {
                            let key = key.trim();
                            let val = val.trim().trim_matches('"').trim_matches('\'');
                            if std::env::var(key).is_err() {
                                std::env::set_var(key, val);
                            }
                        }
                    }
                }
            }
        }
    }
}

fn collect_prompt_files(dir: &Path, out: &mut Vec<PathBuf>) {
    let entries = match std::fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_dir() {
            // Skip hidden directories (.genai.*, .DS_Store dirs, etc.)
            if path
                .file_name()
                .and_then(|n| n.to_str())
                .map(|n| n.starts_with('.'))
                .unwrap_or(false)
            {
                continue;
            }
            collect_prompt_files(&path, out);
        } else if path.is_file()
            && path
                .file_name()
                .and_then(|n| n.to_str())
                .map(|n| n.ends_with(".prompt"))
                .unwrap_or(false)
        {
            out.push(path);
        }
    }
}

fn select_prompt_files(files: Vec<PathBuf>, roots: &[PathBuf]) -> color_eyre::Result<Vec<PathBuf>> {
    let files = normalize_prompt_files(files);
    let labels: Vec<String> = files
        .iter()
        .map(|path| selection_label(path, roots))
        .collect();
    let defaults = vec![true; labels.len()];

    ui::step(&format!(
        "Select prompt files ({} found; Space toggles, Enter accepts)",
        labels.len()
    ));

    let selected = MultiSelect::new()
        .with_prompt("Prompt files to process")
        .items(&labels)
        .defaults(&defaults)
        .interact_opt()?;

    let selected = selected.ok_or_else(|| color_eyre::eyre::eyre!("Prompt selection cancelled"))?;

    let selected_files: Vec<PathBuf> = selected
        .into_iter()
        .filter_map(|index| files.get(index).cloned())
        .collect();

    if selected_files.is_empty() {
        color_eyre::eyre::bail!("No prompt files selected");
    }

    ui::ok(&format!("Selected {} prompt file(s)", selected_files.len()));
    Ok(selected_files)
}

fn selection_label(path: &Path, roots: &[PathBuf]) -> String {
    for root in roots {
        if let Ok(canonical_root) = root.canonicalize() {
            if let Ok(relative) = path.strip_prefix(&canonical_root) {
                return format!("{}/{}", root.display(), relative.display());
            }
        }
    }

    if let Ok(cwd) = std::env::current_dir() {
        if let Ok(relative) = path.strip_prefix(cwd) {
            return relative.display().to_string();
        }
    }

    path.display().to_string()
}

fn normalize_prompt_files(files: Vec<PathBuf>) -> Vec<PathBuf> {
    let mut seen = HashSet::new();
    let mut normalized = Vec::new();

    for path in files {
        let path = path.canonicalize().unwrap_or(path);
        let key = path.to_string_lossy().into_owned();
        if seen.insert(key) {
            normalized.push(path);
        }
    }

    normalized.sort();
    normalized
}

fn launch_zellij_batches(prompt_files: &[PathBuf], cli: &Cli) -> color_eyre::Result<()> {
    if std::env::var_os("ZELLIJ").is_none() {
        color_eyre::eyre::bail!("-j/--jobs requires running inside a zellij session");
    }

    let pane_count = cli.jobs.min(prompt_files.len());
    let batches = build_zellij_batches(prompt_files, pane_count)?;

    if batches.is_empty() {
        color_eyre::eyre::bail!("No prompt batches to launch");
    }

    ui::step(&format!(
        "Launching {} zellij batch pane(s) for {} prompt file(s)",
        batches.len(),
        prompt_files.len()
    ));

    let exe = std::env::current_exe()
        .map_err(|e| color_eyre::eyre::eyre!("Failed to resolve current executable: {}", e))?;
    let cwd = std::env::current_dir()
        .map_err(|e| color_eyre::eyre::eyre!("Failed to resolve current directory: {}", e))?;

    for (index, batch) in batches.iter().enumerate() {
        let pane_name = format!("media-batch-{}-of-{}", index + 1, batches.len());
        let mut command = Command::new("zellij");
        command
            .arg("run")
            .arg("--name")
            .arg(&pane_name)
            .arg("--cwd")
            .arg(&cwd)
            .arg("--")
            .arg(&exe);

        append_worker_args(&mut command, cli);
        for file in batch {
            command.arg(file);
        }

        let status = command.status().map_err(|e| {
            color_eyre::eyre::eyre!("Failed to launch zellij pane '{}': {}", pane_name, e)
        })?;

        if !status.success() {
            color_eyre::eyre::bail!("zellij failed to launch pane '{}'", pane_name);
        }

        ui::ok(&format!("{}: {} prompt file(s)", pane_name, batch.len()));
    }

    Ok(())
}

fn append_worker_args(command: &mut Command, cli: &Cli) {
    command.arg("-n").arg(cli.variants.to_string());

    if cli.dry_run {
        command.arg("--dry-run");
    }
    if cli.force {
        command.arg("--force");
    }
    if cli.refine {
        command.arg("--refine");
    }
    if let Some(model) = &cli.model {
        command.arg("--model").arg(model);
    }
    if cli.verbose {
        command.arg("--verbose");
    }
    if let Some(quality) = &cli.quality {
        command.arg("--quality").arg(quality);
    }
    if let Some(service) = &cli.service {
        command.arg("--service").arg(service);
    }
    if cli.no_eval {
        command.arg("--no-eval");
    }
    if cli.no_prep {
        command.arg("--no-prep");
    }
    if cli.no_fim {
        command.arg("--no-fim");
    }
    if let Some(eval_url) = &cli.eval_url {
        command.arg("--eval-url").arg(eval_url);
    }
    if let Some(eval_model) = &cli.eval_model {
        command.arg("--eval-model").arg(eval_model);
    }
}

fn build_zellij_batches(
    prompt_files: &[PathBuf],
    pane_count: usize,
) -> color_eyre::Result<Vec<Vec<PathBuf>>> {
    if pane_count == 0 || prompt_files.is_empty() {
        return Ok(Vec::new());
    }

    let prompts = prompt_files
        .iter()
        .map(|path| parse_prompt_file(path))
        .collect::<color_eyre::Result<Vec<_>>>()?;

    let groups = dependency_groups(&prompts)?;
    let mut batches = vec![Vec::new(); pane_count];
    let mut batch_sizes = vec![0usize; pane_count];

    for group in groups {
        let batch_index = batch_sizes
            .iter()
            .enumerate()
            .min_by_key(|(_, size)| **size)
            .map(|(index, _)| index)
            .unwrap_or(0);

        for prompt_index in group {
            batches[batch_index].push(prompt_files[prompt_index].clone());
            batch_sizes[batch_index] += 1;
        }
    }

    batches.retain(|batch| !batch.is_empty());
    Ok(batches)
}

fn dependency_groups(prompts: &[ParsedPrompt]) -> color_eyre::Result<Vec<Vec<usize>>> {
    let mut by_id: HashMap<String, usize> = HashMap::new();
    let mut by_path: HashMap<String, usize> = HashMap::new();

    for (index, prompt) in prompts.iter().enumerate() {
        if by_id.insert(prompt.meta.id.clone(), index).is_some() {
            color_eyre::eyre::bail!("Duplicate prompt ID: {}", prompt.meta.id);
        }
        by_path.insert(path_key(&prompt.meta.path), index);
    }

    let mut dsu = DisjointSet::new(prompts.len());

    for (index, prompt) in prompts.iter().enumerate() {
        for dep in &prompt.payload.depends_on {
            let ref_id = dep.ref_id();
            let dependency_index = if let Some(found) = by_id.get(ref_id) {
                *found
            } else {
                let dep_path = prompt.meta.output_dir.join(ref_id);
                let dep_key = path_key(&dep_path);
                *by_path.get(&dep_key).ok_or_else(|| {
                    color_eyre::eyre::eyre!(
                        "Selected prompt {} depends on '{}' but that prompt was not selected",
                        prompt.meta.path.display(),
                        ref_id
                    )
                })?
            };

            dsu.union(index, dependency_index);
        }
    }

    let mut by_root: HashMap<usize, Vec<usize>> = HashMap::new();
    for index in 0..prompts.len() {
        by_root.entry(dsu.find(index)).or_default().push(index);
    }

    let mut groups: Vec<Vec<usize>> = by_root.into_values().collect();
    groups.sort_by_key(|group| group.iter().copied().min().unwrap_or(usize::MAX));
    Ok(groups)
}

fn path_key(path: &Path) -> String {
    path.canonicalize()
        .unwrap_or_else(|_| path.to_path_buf())
        .to_string_lossy()
        .into_owned()
}

struct DisjointSet {
    parent: Vec<usize>,
    rank: Vec<usize>,
}

impl DisjointSet {
    fn new(len: usize) -> Self {
        Self {
            parent: (0..len).collect(),
            rank: vec![0; len],
        }
    }

    fn find(&mut self, index: usize) -> usize {
        if self.parent[index] != index {
            self.parent[index] = self.find(self.parent[index]);
        }
        self.parent[index]
    }

    fn union(&mut self, left: usize, right: usize) {
        let left_root = self.find(left);
        let right_root = self.find(right);

        if left_root == right_root {
            return;
        }

        match self.rank[left_root].cmp(&self.rank[right_root]) {
            std::cmp::Ordering::Less => self.parent[left_root] = right_root,
            std::cmp::Ordering::Greater => self.parent[right_root] = left_root,
            std::cmp::Ordering::Equal => {
                self.parent[right_root] = left_root;
                self.rank[left_root] += 1;
            }
        }
    }
}
