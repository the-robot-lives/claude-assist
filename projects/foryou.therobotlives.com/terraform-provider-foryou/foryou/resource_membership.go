package foryou

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type membershipResource struct{ client *Client }

func NewMembershipResource() resource.Resource { return &membershipResource{} }

func (r *membershipResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_membership"
}

func (r *membershipResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":             schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"organization_id": schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"user_id":        schema.StringAttribute{Required: true, PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()}},
			"role":           schema.StringAttribute{Required: true},
		},
	}
}

func (r *membershipResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type membershipModel struct {
	ID             types.String `tfsdk:"id"`
	OrganizationID types.String `tfsdk:"organization_id"`
	UserID         types.String `tfsdk:"user_id"`
	Role           types.String `tfsdk:"role"`
}

type memberAPI struct {
	UserID string `json:"user_id"`
	Role   string `json:"role"`
}

func compositeID(org, user string) string { return fmt.Sprintf("%s/%s", org, user) }

func (r *membershipResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m membershipModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	path := fmt.Sprintf("/organizations/%s/memberships", m.OrganizationID.ValueString())
	body := map[string]any{"membership": map[string]any{"user_id": m.UserID.ValueString(), "role": m.Role.ValueString()}}
	if _, err := r.client.do(ctx, "POST", path, body, nil); err != nil {
		resp.Diagnostics.AddError("Create foryou_membership", err.Error())
		return
	}
	m.ID = types.StringValue(compositeID(m.OrganizationID.ValueString(), m.UserID.ValueString()))
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *membershipResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m membershipModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	path := fmt.Sprintf("/organizations/%s/memberships", m.OrganizationID.ValueString())
	var out struct {
		Memberships []memberAPI `json:"memberships"`
	}
	status, err := r.client.do(ctx, "GET", path, nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_membership", err.Error())
		return
	}
	var found *memberAPI
	for i := range out.Memberships {
		if out.Memberships[i].UserID == m.UserID.ValueString() {
			found = &out.Memberships[i]
			break
		}
	}
	if found == nil {
		resp.State.RemoveResource(ctx)
		return
	}
	m.Role = types.StringValue(found.Role)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *membershipResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m membershipModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state membershipModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.OrganizationID = state.OrganizationID
	m.UserID = state.UserID

	path := fmt.Sprintf("/organizations/%s/memberships/%s", m.OrganizationID.ValueString(), m.UserID.ValueString())
	body := map[string]any{"membership": map[string]any{"role": m.Role.ValueString()}}
	if _, err := r.client.do(ctx, "PATCH", path, body, nil); err != nil {
		resp.Diagnostics.AddError("Update foryou_membership", err.Error())
		return
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *membershipResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m membershipModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	path := fmt.Sprintf("/organizations/%s/memberships/%s", m.OrganizationID.ValueString(), m.UserID.ValueString())
	status, err := r.client.do(ctx, "DELETE", path, nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_membership", err.Error())
		return
	}
}
