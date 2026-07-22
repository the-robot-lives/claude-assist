package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type formResource struct{ client *Client }

func NewFormResource() resource.Resource { return &formResource{} }

func (r *formResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_form"
}

func (r *formResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":                schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"organization_id":   schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"slug":              schema.StringAttribute{Required: true},
			"name":              schema.StringAttribute{Required: true},
			"status":            schema.StringAttribute{Optional: true, Computed: true},
			"definition":        schema.StringAttribute{Optional: true, Description: "Form definition as a JSON string (use jsonencode()). On change, a new immutable version is minted."},
			"settings":          schema.StringAttribute{Optional: true, Description: "Arbitrary settings as a JSON string."},
			"current_version_id": schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
		},
	}
}

func (r *formResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type formModel struct {
	ID               types.String `tfsdk:"id"`
	OrganizationID   types.String `tfsdk:"organization_id"`
	Slug             types.String `tfsdk:"slug"`
	Name             types.String `tfsdk:"name"`
	Status           types.String `tfsdk:"status"`
	Definition       types.String `tfsdk:"definition"`
	Settings         types.String `tfsdk:"settings"`
	CurrentVersionID types.String `tfsdk:"current_version_id"`
}

type formAPI struct {
	ID               string          `json:"id"`
	OrganizationID   string          `json:"organization_id"`
	Slug             string          `json:"slug"`
	Name             string          `json:"name"`
	Status           string          `json:"status"`
	Definition       map[string]any  `json:"definition"`
	Settings         map[string]any  `json:"settings"`
	CurrentVersionID string          `json:"current_version_id"`
}

func (m formModel) payload() map[string]any {
	form := map[string]any{
		"organization_id": m.OrganizationID.ValueString(),
		"slug":            m.Slug.ValueString(),
		"name":            m.Name.ValueString(),
	}
	if v := m.Status.ValueString(); v != "" {
		form["status"] = v
	}
	if dm, ok := parseJSONMap(m.Definition.ValueString()); ok {
		form["definition"] = dm
	}
	if sm, ok := parseJSONMap(m.Settings.ValueString()); ok {
		form["settings"] = sm
	}
	return map[string]any{"form": form}
}

func (r *formResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m formModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Form formAPI `json:"form"`
	}
	if _, err := r.client.do(ctx, "POST", "/forms", m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_form", err.Error())
		return
	}
	applyFormAPI(&m, out.Form)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *formResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m formModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Form formAPI `json:"form"`
	}
	status, err := r.client.do(ctx, "GET", "/forms/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_form", err.Error())
		return
	}
	applyFormAPI(&m, out.Form)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *formResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m formModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state formModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.ID = state.ID

	var out struct {
		Form formAPI `json:"form"`
	}
	if _, err := r.client.do(ctx, "PATCH", "/forms/"+m.ID.ValueString(), m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Update foryou_form", err.Error())
		return
	}
	applyFormAPI(&m, out.Form)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *formResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m formModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/forms/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_form", err.Error())
		return
	}
}

// applyFormAPI maps a server response onto the model (re-encoding jsonb fields
// to canonical JSON strings so plan diffs are stable).
func applyFormAPI(m *formModel, f formAPI) {
	m.ID = types.StringValue(f.ID)
	m.OrganizationID = types.StringValue(f.OrganizationID)
	m.Slug = types.StringValue(f.Slug)
	m.Name = types.StringValue(f.Name)
	m.Status = types.StringValue(f.Status)
	m.CurrentVersionID = types.StringValue(f.CurrentVersionID)
	if f.Definition != nil {
		m.Definition = types.StringValue(encodeJSON(f.Definition))
	}
	if f.Settings != nil {
		m.Settings = types.StringValue(encodeJSON(f.Settings))
	}
}
