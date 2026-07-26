defmodule GottaCcWeb.OptionalAuthPipeline do
  @moduledoc """
  Auth pipeline for endpoints that serve anonymous traffic but still want to
  attribute the actor when a session happens to be present. Same as
  `GottaCcWeb.AuthPipeline` minus `EnsureAuthenticated`; a missing token leaves
  `Guardian.Plug.current_resource/1` as nil rather than halting with a 401.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :gotta_cc,
    module: GottaCc.Guardian,
    error_handler: GottaCcWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end
