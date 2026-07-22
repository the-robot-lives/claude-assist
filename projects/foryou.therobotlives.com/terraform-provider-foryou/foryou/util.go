package foryou

import "encoding/json"

// parseJSONMap decodes a JSON object string; returns ok=false on empty/invalid.
func parseJSONMap(s string) (map[string]any, bool) {
	if s == "" {
		return nil, false
	}
	var m map[string]any
	if err := json.Unmarshal([]byte(s), &m); err != nil {
		return nil, false
	}
	return m, true
}

// parseJSONArray decodes a JSON array string; returns ok=false on empty/invalid.
func parseJSONArray(s string) ([]any, bool) {
	if s == "" {
		return nil, false
	}
	var a []any
	if err := json.Unmarshal([]byte(s), &a); err != nil {
		return nil, false
	}
	return a, true
}

// encodeJSON marshals v; empty string on error/nil.
func encodeJSON(v any) string {
	if v == nil {
		return ""
	}
	b, err := json.Marshal(v)
	if err != nil {
		return ""
	}
	return string(b)
}
