package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// listResource provisions a foryou List (one per site is the listmonk-cutover
// vehicle). CRUD against /api/v1/management/lists. Idempotent: re-applying the
// same spec updates in place; removal archives (soft) rather than hard-deletes.
type listResource struct{ client *Client }

func NewListResource() resource.Resource { return &listResource{} }

func (r *listResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_list"
}

func (r *listResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":          schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"project_id":  schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"slug":        schema.StringAttribute{Required: true},
			"public_slug": schema.StringAttribute{Required: true, Description: "Globally-unique public key the signup endpoint + widget resolve by."},
			"name":        schema.StringAttribute{Required: true},
			"description": schema.StringAttribute{Optional: true},
			"kind":        schema.StringAttribute{Optional: true, Computed: true, Description: "newsletter | waitlist | inquiry | contact | mixed"},
			"status":      schema.StringAttribute{Optional: true, Computed: true},
			"settings":    schema.StringAttribute{Optional: true, Description: "Arbitrary settings as a JSON string (use jsonencode()); e.g. opt_in_mode, sender_identity."},
			"attributes":  schema.StringAttribute{Optional: true, Description: "Typed attributes as a JSON array string (use jsonencode([...])). Write-only idempotent upsert by slug: sent on create/update but never read back into state (the server enriches the objects), so state keeps your config value and there is no drift detection on this field."},
		},
	}
}

func (r *listResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type listModel struct {
	ID          types.String `tfsdk:"id"`
	ProjectID   types.String `tfsdk:"project_id"`
	Slug        types.String `tfsdk:"slug"`
	PublicSlug  types.String `tfsdk:"public_slug"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Kind        types.String `tfsdk:"kind"`
	Status      types.String `tfsdk:"status"`
	Settings    types.String `tfsdk:"settings"`
	Attributes  types.String `tfsdk:"attributes"`
}

type listAPI struct {
	ID          string           `json:"id"`
	ProjectID   string           `json:"project_id"`
	Slug        string           `json:"slug"`
	PublicSlug  string           `json:"public_slug"`
	Name        string           `json:"name"`
	Description string           `json:"description"`
	Kind        string           `json:"kind"`
	Status      string           `json:"status"`
	Settings    map[string]any   `json:"settings"`
	Attributes  []map[string]any `json:"attributes"`
}

func (m listModel) payload() map[string]any {
	list := map[string]any{
		"project_id":  m.ProjectID.ValueString(),
		"slug":        m.Slug.ValueString(),
		"public_slug": m.PublicSlug.ValueString(),
		"name":        m.Name.ValueString(),
	}
	if v := m.Description.ValueString(); v != "" {
		list["description"] = v
	}
	if v := m.Kind.ValueString(); v != "" {
		list["kind"] = v
	}
	if v := m.Status.ValueString(); v != "" {
		list["status"] = v
	}
	if sm, ok := parseJSONMap(m.Settings.ValueString()); ok {
		list["settings"] = sm
	}
	if am, ok := parseJSONArray(m.Attributes.ValueString()); ok {
		list["attributes"] = am
	}
	return map[string]any{"list": list}
}

func (r *listResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m listModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		List listAPI `json:"list"`
	}
	if _, err := r.client.do(ctx, "POST", "/lists", m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_list", err.Error())
		return
	}
	applyListAPI(&m, out.List)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *listResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m listModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		List listAPI `json:"list"`
	}
	status, err := r.client.do(ctx, "GET", "/lists/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_list", err.Error())
		return
	}
	applyListAPI(&m, out.List)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *listResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m listModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state listModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.ID = state.ID

	var out struct {
		List listAPI `json:"list"`
	}
	if _, err := r.client.do(ctx, "PATCH", "/lists/"+m.ID.ValueString(), m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Update foryou_list", err.Error())
		return
	}
	applyListAPI(&m, out.List)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *listResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m listModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/lists/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_list", err.Error())
		return
	}
}

// applyListAPI maps a server response onto the model. `settings` is re-encoded
// to a canonical JSON string only when the config set it, so an unset optional
// stays null and plan diffs stay stable.
//
// `attributes` is deliberately NOT read back from the server: it is a write-only
// idempotent upsert. The server enriches each attribute object on read (adds
// id/status and null-valued options/validation), so echoing that enriched JSON
// into state would never match the sparse config's jsonencode — causing
// "inconsistent result after apply" on create and perpetual in-place diffs
// thereafter. Leaving m.Attributes untouched preserves the config/plan value on
// Create/Update and the prior state value on Read (the owner_user_id pattern in
// resource_project.go).
func applyListAPI(m *listModel, l listAPI) {
	m.ID = types.StringValue(l.ID)
	m.ProjectID = types.StringValue(l.ProjectID)
	m.Slug = types.StringValue(l.Slug)
	m.PublicSlug = types.StringValue(l.PublicSlug)
	m.Name = types.StringValue(l.Name)
	m.Kind = types.StringValue(l.Kind)
	m.Status = types.StringValue(l.Status)
	if l.Description != "" {
		m.Description = types.StringValue(l.Description)
	}
	if !m.Settings.IsNull() && l.Settings != nil {
		m.Settings = types.StringValue(encodeJSON(l.Settings))
	}
}
