package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// projectResource provisions a foryou Project. A Project belongs to an
// Organization and owns Lists (foryou_list.project_id references it). CRUD
// against /api/v1/management/projects. Idempotent: re-applying the same spec
// updates in place; removal soft-archives rather than hard-deletes.
type projectResource struct{ client *Client }

func NewProjectResource() resource.Resource { return &projectResource{} }

func (r *projectResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_project"
}

func (r *projectResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":              schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"organization_id": schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}, Description: "UUID of the owning Organization. Changing this replaces the Project."},
			"slug":            schema.StringAttribute{Required: true},
			"name":            schema.StringAttribute{Required: true},
			"description":     schema.StringAttribute{Optional: true},
			"status":          schema.StringAttribute{Optional: true, Computed: true},
			"settings":        schema.StringAttribute{Optional: true, Description: "Arbitrary settings as a JSON string (use jsonencode())."},
			"owner_user_id":   schema.StringAttribute{Optional: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}, Description: "If set at create, grants this user a project-level owner membership (required for authed detail/lists/signups access). Create-only; the API ignores it on update and does not echo it on read, so it is config-only with no drift detection."},
		},
	}
}

func (r *projectResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type projectModel struct {
	ID             types.String `tfsdk:"id"`
	OrganizationID types.String `tfsdk:"organization_id"`
	Slug           types.String `tfsdk:"slug"`
	Name           types.String `tfsdk:"name"`
	Description    types.String `tfsdk:"description"`
	Status         types.String `tfsdk:"status"`
	Settings       types.String `tfsdk:"settings"`
	OwnerUserID    types.String `tfsdk:"owner_user_id"`
}

type projectAPI struct {
	ID             string         `json:"id"`
	OrganizationID string         `json:"organization_id"`
	Slug           string         `json:"slug"`
	Name           string         `json:"name"`
	Description    string         `json:"description"`
	Status         string         `json:"status"`
	Settings       map[string]any `json:"settings"`
}

func (m projectModel) payload() map[string]any {
	project := map[string]any{
		"organization_id": m.OrganizationID.ValueString(),
		"slug":            m.Slug.ValueString(),
		"name":            m.Name.ValueString(),
	}
	if v := m.Description.ValueString(); v != "" {
		project["description"] = v
	}
	if v := m.Status.ValueString(); v != "" {
		project["status"] = v
	}
	if sm, ok := parseJSONMap(m.Settings.ValueString()); ok {
		project["settings"] = sm
	}
	// Create-only: grants a project owner membership. PATCH ignores it; harmless
	// to include since payload() is also used by Update (value is ForceNew).
	if v := m.OwnerUserID.ValueString(); v != "" {
		project["owner_user_id"] = v
	}
	return map[string]any{"project": project}
}

func (r *projectResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m projectModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Project projectAPI `json:"project"`
	}
	if _, err := r.client.do(ctx, "POST", "/projects", m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_project", err.Error())
		return
	}
	applyProjectAPI(&m, out.Project)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *projectResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m projectModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Project projectAPI `json:"project"`
	}
	status, err := r.client.do(ctx, "GET", "/projects/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_project", err.Error())
		return
	}
	applyProjectAPI(&m, out.Project)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *projectResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m projectModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state projectModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.ID = state.ID

	var out struct {
		Project projectAPI `json:"project"`
	}
	if _, err := r.client.do(ctx, "PATCH", "/projects/"+m.ID.ValueString(), m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Update foryou_project", err.Error())
		return
	}
	applyProjectAPI(&m, out.Project)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *projectResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m projectModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/projects/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_project", err.Error())
		return
	}
}

// applyProjectAPI maps a server response onto the model. `settings` is
// re-encoded to a canonical JSON string only when the config set it, so an unset
// optional stays null and plan diffs stay stable. `owner_user_id` is ForceNew
// and never echoed by the API, so it is deliberately left untouched here and
// preserved from config/state.
func applyProjectAPI(m *projectModel, p projectAPI) {
	m.ID = types.StringValue(p.ID)
	m.OrganizationID = types.StringValue(p.OrganizationID)
	m.Slug = types.StringValue(p.Slug)
	m.Name = types.StringValue(p.Name)
	m.Status = types.StringValue(p.Status)
	if p.Description != "" {
		m.Description = types.StringValue(p.Description)
	}
	if !m.Settings.IsNull() && p.Settings != nil {
		m.Settings = types.StringValue(encodeJSON(p.Settings))
	}
}
