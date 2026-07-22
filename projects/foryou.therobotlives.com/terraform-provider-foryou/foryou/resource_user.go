package foryou

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type userResource struct{ client *Client }

func NewUserResource() resource.Resource { return &userResource{} }

func (r *userResource) Metadata(_ context.Context, _ resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = "foryou_user"
}

func (r *userResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"id":         schema.StringAttribute{Computed: true, PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()}},
			"user_name":  schema.StringAttribute{Required: true},
			"email":      schema.StringAttribute{Required: true},
			"password":   schema.StringAttribute{Required: true, Sensitive: true, Description: "Write-only: never returned by the API; preserved in state."},
			"handle":     schema.StringAttribute{Optional: true, Computed: true},
			"name_first": schema.StringAttribute{Optional: true},
			"name_last":  schema.StringAttribute{Optional: true},
			"status":     schema.StringAttribute{Optional: true, Computed: true},
			"verified":   schema.BoolAttribute{Optional: true, Computed: true},
			"flagged":    schema.BoolAttribute{Optional: true, Computed: true},
		},
	}
}

func (r *userResource) Configure(_ context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	r.client = configureClient(req, resp)
}

type userModel struct {
	ID        types.String `tfsdk:"id"`
	UserName  types.String `tfsdk:"user_name"`
	Email     types.String `tfsdk:"email"`
	Password  types.String `tfsdk:"password"`
	Handle    types.String `tfsdk:"handle"`
	NameFirst types.String `tfsdk:"name_first"`
	NameLast  types.String `tfsdk:"name_last"`
	Status    types.String `tfsdk:"status"`
	Verified  types.Bool   `tfsdk:"verified"`
	Flagged   types.Bool   `tfsdk:"flagged"`
}

type userAPI struct {
	ID       string `json:"id"`
	UserName string `json:"user_name"`
	Email    string `json:"email"`
	Handle   string `json:"handle"`
	Status   string `json:"status"`
	Verified bool   `json:"verified"`
	Flagged  bool   `json:"flagged"`
}

func (m userModel) payload() map[string]any {
	user := map[string]any{
		"user_name": m.UserName.ValueString(),
		"email":     m.Email.ValueString(),
		"password":  m.Password.ValueString(),
		"name":      map[string]any{"first": m.NameFirst.ValueString(), "last": m.NameLast.ValueString()},
	}
	if v := m.Handle.ValueString(); v != "" {
		user["handle"] = v
	}
	if v := m.Status.ValueString(); v != "" {
		user["status"] = v
	}
	if !m.Verified.IsNull() {
		user["verified"] = m.Verified.ValueBool()
	}
	if !m.Flagged.IsNull() {
		user["flagged"] = m.Flagged.ValueBool()
	}
	return map[string]any{"user": user}
}

func (r *userResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var m userModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		User userAPI `json:"user"`
	}
	if _, err := r.client.do(ctx, "POST", "/users", m.payload(), &out); err != nil {
		resp.Diagnostics.AddError("Create foryou_user", err.Error())
		return
	}
	m.ID = types.StringValue(out.User.ID)
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *userResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var m userModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var out struct {
		User userAPI `json:"user"`
	}
	status, err := r.client.do(ctx, "GET", "/users/"+m.ID.ValueString(), nil, &out)
	if status == 404 {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Read foryou_user", err.Error())
		return
	}
	m.UserName = types.StringValue(out.User.UserName)
	m.Email = types.StringValue(out.User.Email)
	m.Handle = types.StringValue(out.User.Handle)
	m.Status = types.StringValue(out.User.Status)
	m.Verified = types.BoolValue(out.User.Verified)
	m.Flagged = types.BoolValue(out.User.Flagged)
	// password preserved from state
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *userResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var m userModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	var state userModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	m.ID = state.ID

	if _, err := r.client.do(ctx, "PATCH", "/users/"+m.ID.ValueString(), m.payload(), nil); err != nil {
		resp.Diagnostics.AddError("Update foryou_user", err.Error())
		return
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &m)...)
}

func (r *userResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var m userModel
	resp.Diagnostics.Append(req.State.Get(ctx, &m)...)
	if resp.Diagnostics.HasError() {
		return
	}
	status, err := r.client.do(ctx, "DELETE", "/users/"+m.ID.ValueString(), nil, nil)
	if status == 404 {
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Delete foryou_user", err.Error())
		return
	}
}
