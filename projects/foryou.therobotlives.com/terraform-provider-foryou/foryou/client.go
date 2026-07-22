package foryou

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"github.com/hashicorp/terraform-plugin-framework/resource"
)

// Client talks to the foryou management API (/api/v1/management).
type Client struct {
	baseURL string
	apiKey  string
	http    *http.Client
}

func NewClient(host, apiKey string) (*Client, error) {
	u, err := url.Parse(host)
	if err != nil {
		return nil, fmt.Errorf("invalid host: %w", err)
	}
	base := u.String()
	// avoid a doubled slash if host already ends with /
	if len(base) > 0 && base[len(base)-1] == '/' {
		base = base[:len(base)-1]
	}
	return &Client{
		baseURL: base + "/api/v1/management",
		apiKey:  apiKey,
		http:    &http.Client{Timeout: 30 * time.Second},
	}, nil
}

// do performs an HTTP request against the management API. `in` is JSON-encoded
// as the body when non-nil; `out` is decoded from a 2xx response when non-nil.
// Returns the status code and an error. A non-2xx status is returned as an
// error carrying the status code and body; callers may inspect the returned
// status (e.g. 404) before treating the error as fatal.
func (c *Client) do(ctx context.Context, method, path string, in interface{}, out interface{}) (int, error) {
	var body io.Reader
	if in != nil {
		b, err := json.Marshal(in)
		if err != nil {
			return 0, fmt.Errorf("marshal request: %w", err)
		}
		body = bytes.NewReader(b)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, body)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	res, err := c.http.Do(req)
	if err != nil {
		return 0, err
	}
	defer res.Body.Close()

	raw, _ := io.ReadAll(res.Body)

	if res.StatusCode/100 != 2 {
		return res.StatusCode, fmt.Errorf("status %d: %s", res.StatusCode, string(raw))
	}

	if out != nil && len(raw) > 0 {
		if err := json.Unmarshal(raw, out); err != nil {
			return res.StatusCode, fmt.Errorf("decode response: %w", err)
		}
	}
	return res.StatusCode, nil
}

// configureClient pulls the *Client injected by the provider, or errors.
func configureClient(req resource.ConfigureRequest, resp *resource.ConfigureResponse) *Client {
	if req.ProviderData == nil {
		return nil
	}
	client, ok := req.ProviderData.(*Client)
	if !ok {
		resp.Diagnostics.AddError("Unexpected provider data", fmt.Sprintf("expected *foryou.Client, got %T", req.ProviderData))
		return nil
	}
	return client
}
