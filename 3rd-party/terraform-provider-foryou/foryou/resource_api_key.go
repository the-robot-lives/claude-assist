package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/listplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type apiKeyResource struct{ client *Client }

func NewAPIKeyResource() resource.Resource { return &apiKeyResource{} }

func (r *apiKeyResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_api_key"
}

func (r *apiKeyResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":            schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"name":          schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"owner_user_id": schema.StringAttribute{Optional: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"scopes": schema.ListAttribute{
				ElementType:  types.StringType,
				Optional:     true,
				PlanModifiers: []planmodifier.List{listplanmodifier.RequiresReplace()},
			},
			"expires_at": schema.StringAttribute{Optional: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"key_prefix": schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"secret":     schema.StringAttribute{Computed: true, Sensitive: true, Description: "Write-only: returned only at create; never recoverable.", PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
		},
	}
}

func (r *apiKeyResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type apiKeyModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	OwnerUserID types.String `tfsdk:"owner_user_id"`
	Scopes      types.List   `tfsdk:"scopes"`
	ExpiresAt   types.String `tfsdk:"expires_at"`
	KeyPrefix   types.String `tfsdk:"key_prefix"`
	Secret      types.String `tfsdk:"secret"`
}

type apiKeyAPI struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	KeyPrefix string   `json:"key_prefix"`
	Scopes    []string `json:"scopes"`
	Status    string   `json:"status"`
	Secret    string   `json:"secret"`
}

func (m apiKeyModel) payload(ctx context.Context, resp *resource.CreateResponse) map[string]any {
	ak := map[string]any{"name": m.Name.ValueString()}
	if v := m.OwnerUserID.ValueString(); v != "" {
		ak["owner_user_id"] = v
	}
	if !m.Scopes.IsNull() {
		var scopes []string
		resp.Diagnostics.Append(m.Scopes.ElementsAs(ctx, &scopes, false)...)
		if len(scopes) > 0 {
			ak["scopes"] = scopes
		}
	}
	if v := m.ExpiresAt.ValueString(); v != "" {
		ak["expires_at"] = v
	}
	return map[string]any{"api_key": ak}
}

func (r *apiKeyResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m apiKeyModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		APIKey apiKeyAPI `json:"api_key"`
	}
	if _, err := r.client.do(ctx, "POST", "/api-keys", m.payload(ctx, resp), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_api_key", err.Error())
		return
	}
	m.ID = types.StringValue(out.APIKey.ID)
	m.KeyPrefix = types.StringValue(out.APIKey.KeyPrefix)
	if out.APIKey.Secret != "" {
		m.Secret = types.StringValue(out.APIKey.Secret)
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *apiKeyResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m apiKeyModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		APIKey apiKeyAPI `json:"api_key"`
	}
	status, err := r.client.do(ctx, "GET", "/api-keys/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_api_key", err.Error())
		return
	}
	m.KeyPrefix = types.StringValue(out.APIKey.KeyPrefix)
	// name/owner/scopes/expires_at are ForceNew — preserve from state.
	// secret never returned — preserve from state.
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *apiKeyResource) Update(ctx context.Context, _ resource.UpdateRequest, _ *resource.UpdateResponse) {
	// All mutable attributes force replacement; no in-place update path.
}

func (r *apiKeyResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m apiKeyModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/api-keys/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_api_key", err.Error())
		return
	}
}
