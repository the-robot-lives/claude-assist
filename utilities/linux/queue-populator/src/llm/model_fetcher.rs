//! Port of Sources/LLM/ModelFetcher.swift — best-effort model list for the
//! config UI dropdown; all failures collapse to an empty list.

use std::io::Read;
use std::time::Duration;

const MAX_MODEL_RESPONSE_BYTES: u64 = 2 * 1024 * 1024;

pub fn fetch_models(provider: &str, api_key: Option<&str>, base_url: Option<&str>) -> Vec<String> {
    match provider {
        "anthropic" => fetch_anthropic(api_key),
        "openai" => fetch_openai_compatible("https://api.openai.com/v1/models", api_key),
        "groq" => fetch_openai_compatible("https://api.groq.com/openai/v1/models", api_key),
        "cerebras" => fetch_openai_compatible("https://api.cerebras.ai/v1/models", api_key),
        "deepseek" => fetch_openai_compatible("https://api.deepseek.com/v1/models", api_key),
        "zai" => fetch_openai_compatible("https://open.bigmodel.cn/api/paas/v4/models", api_key),
        "litellm" => {
            let base = base_url.filter(|b| !b.is_empty()).unwrap_or("https://inference.noizu.com/v1");
            fetch_openai_compatible(&join_url(base, "models"), api_key)
        }
        "ollama" => {
            let base = base_url.filter(|b| !b.is_empty()).unwrap_or("http://localhost:11434");
            fetch_ollama(&join_url(base, "api/tags"))
        }
        "custom" => match base_url.filter(|b| !b.is_empty()) {
            Some(base) => fetch_openai_compatible(&join_url(base, "models"), api_key),
            None => vec![],
        },
        _ => vec![],
    }
}

fn join_url(base: &str, path: &str) -> String {
    format!("{}/{}", base.trim_end_matches('/'), path.trim_start_matches('/'))
}

fn agent() -> ureq::Agent {
    ureq::AgentBuilder::new().timeout(Duration::from_secs(10)).build()
}

fn fetch_anthropic(api_key: Option<&str>) -> Vec<String> {
    let Some(key) = api_key.filter(|k| !k.is_empty()) else {
        return vec![];
    };
    let Ok(response) = agent()
        .get("https://api.anthropic.com/v1/models?limit=100")
        .set("x-api-key", key)
        .set("anthropic-version", "2023-06-01")
        .call()
    else {
        return vec![];
    };
    let Ok(json) =
        serde_json::from_reader::<_, serde_json::Value>(response.into_reader().take(MAX_MODEL_RESPONSE_BYTES))
    else {
        return vec![];
    };
    let mut ids: Vec<String> = json["data"]
        .as_array()
        .map(|models| {
            models
                .iter()
                .filter_map(|m| m["id"].as_str().map(String::from))
                .collect()
        })
        .unwrap_or_default();
    ids.sort();
    ids
}

fn fetch_openai_compatible(url: &str, api_key: Option<&str>) -> Vec<String> {
    let mut request = agent().get(url);
    if let Some(key) = api_key.filter(|k| !k.is_empty()) {
        request = request.set("Authorization", &format!("Bearer {key}"));
    }
    let Ok(response) = request.call() else {
        return vec![];
    };
    let Ok(json) =
        serde_json::from_reader::<_, serde_json::Value>(response.into_reader().take(MAX_MODEL_RESPONSE_BYTES))
    else {
        return vec![];
    };
    let models = json["data"].as_array().or_else(|| json["models"].as_array());
    let mut names: Vec<String> = models
        .map(|models| {
            models
                .iter()
                .filter_map(|m| m["id"].as_str().or_else(|| m["name"].as_str()).map(String::from))
                .collect()
        })
        .unwrap_or_default();
    names.sort();
    names
}

fn fetch_ollama(url: &str) -> Vec<String> {
    let agent = ureq::AgentBuilder::new().timeout(Duration::from_secs(5)).build();
    let Ok(response) = agent.get(url).call() else {
        return vec![];
    };
    let Ok(json) =
        serde_json::from_reader::<_, serde_json::Value>(response.into_reader().take(MAX_MODEL_RESPONSE_BYTES))
    else {
        return vec![];
    };
    let mut names: Vec<String> = json["models"]
        .as_array()
        .map(|models| {
            models
                .iter()
                .filter_map(|m| m["name"].as_str().map(String::from))
                .collect()
        })
        .unwrap_or_default();
    names.sort();
    names
}

#[cfg(test)]
mod tests {
    use super::join_url;

    #[test]
    fn model_endpoint_join_has_exactly_one_separator() {
        assert_eq!(join_url("http://localhost:11434", "api/tags"), "http://localhost:11434/api/tags");
        assert_eq!(join_url("http://localhost:11434/", "/api/tags"), "http://localhost:11434/api/tags");
        assert_eq!(join_url("https://example.test/v1///", "models"), "https://example.test/v1/models");
    }
}
