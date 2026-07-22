package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type organizationResource struct{ client *Client }

func NewOrganizationResource() resource.Resource { return &organizationResource{} }

func (r *organizationResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_organization"
}

func (r *organizationResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":            schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"slug":          schema.StringAttribute{Required: true},
			"name":          schema.StringAttribute{Required: true},
			"settings":      schema.StringAttribute{Optional: true, Description: "Arbitrary settings as a JSON string (use jsonencode())."},
			"owner_user_id": schema.StringAttribute{Optional: true, Description: "If set at create, links this user as owner (membership created in the same call)."},
		},
	}
}

func (r *organizationResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type organizationModel struct {
	ID          types.String `tfsdk:"id"`
	Slug        types.String `tfsdk:"slug"`
	Name        types.String `tfsdk:"name"`
	Settings    types.String `tfsdk:"settings"`
	OwnerUserID types.String `tfsdk:"owner_user_id"`
}

type organizationAPI struct {
	ID      string          `json:"id"`
	Slug    string          `json:"slug"`
	Name    string          `json:"name"`
	Settings map[string]any `json:"settings"`
}

func (m organizationModel) payload() map[string]any {
	org := map[string]any{"slug": m.Slug.ValueString(), "name": m.Name.ValueString()}
	if sm, ok := parseJSONMap(m.Settings.ValueString()); ok {
		org["settings"] = sm
	}
	if v := m.OwnerUserID.ValueString(); v != "" {
		org["owner_user_id"] = v
	}
	return map[string]any{"organization": org}
}

func (r *organizationResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m organizationModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Organization organizationAPI `json:"organization"`
	}
	if _, err := r.client.do(ctx, "POST", "/organizations", m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_organization", err.Error())
		return
	}
	m.ID = types.StringValue(out.Organization.ID)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *organizationResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m organizationModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		Organization organizationAPI `json:"organization"`
	}
	status, err := r.client.do(ctx, "GET", "/organizations/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_organization", err.Error())
		return
	}
	m.Slug = types.StringValue(out.Organization.Slug)
	m.Name = types.StringValue(out.Organization.Name)
	if out.Organization.Settings != nil {
		m.Settings = types.StringValue(encodeJSON(out.Organization.Settings))
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *organizationResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m organizationModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state organizationModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.ID = state.ID

	if _, err := r.client.do(ctx, "PATCH", "/organizations/"+m.ID.ValueString(), m.payload(), nil); err != nil {
		resp.Diagnostics.AddError("Update foryou_organization", err.Error())
		return
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *organizationResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m organizationModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/organizations/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_organization", err.Error())
		return
	}
}
