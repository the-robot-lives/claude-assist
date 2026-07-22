// Package foryou implements the noizu/foryou Terraform provider.
package foryou

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

const (
	DefaultHost = "https://foryou.therobotlives.com"
	EnvAPIKey   = "FORYOU_API_KEY"
	EnvHost     = "FORYOU_HOST"
)

// Ensure the implementation satisfies the provider interface.
var _ provider.Provider = &foryouProvider{}

type foryouProvider struct {
	version string
}

// New is a helper for the provider server entrypoint.
func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &foryouProvider{version: version}
	}
}

func (p *foryouProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "foryou"
	resp.Version = p.version
}

func (p *foryouProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"api_key": schema.StringAttribute{
				Optional:  true,
				Sensitive: true,
				Description: fmt.Sprintf("API key for the foryou management API. "+
					"Mint one with `bin/foryou eval 'Foryou.Release.mint_api_key(\"terraform\")'`. "+
					"Also settable via the %s environment variable.", EnvAPIKey),
			},
			"host": schema.StringAttribute{
				Optional: true,
				Description: fmt.Sprintf("Base URL of the foryou backend (default %s). "+
					"Also settable via the %s environment variable.", DefaultHost, EnvHost),
			},
		},
	}
}

type foryouProviderModel struct {
	APIKey types.String `tfsdk:"api_key"`
	Host   types.String `tfsdk:"host"`
}

func (p *foryouProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config foryouProviderModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
	if resp.Diagnostics.HasError() {
		return
	}

	apiKey := config.APIKey.ValueString()
	if apiKey == "" {
		apiKey = os.Getenv(EnvAPIKey)
	}

	host := config.Host.ValueString()
	if host == "" {
		host = os.Getenv(EnvHost)
	}
	if host == "" {
		host = DefaultHost
	}

	if apiKey == "" {
		resp.Diagnostics.AddAttributeError(
			path.Root("api_key"),
			"Missing foryou api_key",
			fmt.Sprintf("The provider requires an API key. Set api_key in the provider block or the %s env var.", EnvAPIKey),
		)
		return
	}

	client, err := NewClient(host, apiKey)
	if err != nil {
		resp.Diagnostics.AddError("Unable to create foryou API client", err.Error())
		return
	}

	resp.ResourceData = client
}

func (p *foryouProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewUserResource,
		NewOrganizationResource,
		NewMembershipResource,
		NewFormResource,
		NewAPIKeyResource,
		NewListResource,
	}
}

func (p *foryouProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return nil
}
