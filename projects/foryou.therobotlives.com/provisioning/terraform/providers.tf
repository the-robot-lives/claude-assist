# Provider + shared variables for the foryou List/Project provisioning root.
# Local state (never yet applied). The provider is a local build resolved via
# the OpenTofu filesystem mirror (~/.terraformrc → noizu/foryou); rebuild it
# with terraform-provider-foryou/scripts/build-provider.sh.
#
#   tofu init
#   tofu apply -var "foryou_api_key=$FORYOU_API_KEY"

terraform {
  required_providers {
    foryou = {
      source = "noizu/foryou" # local build; see terraform-provider-foryou/
    }
  }
}

variable "foryou_host" {
  type        = string
  description = "Base URL of the foryou backend."
  default     = "https://foryou.therobotlives.com"
}

variable "foryou_api_key" {
  type        = string
  sensitive   = true
  description = "foryou management API key. Mint with `bin/foryou eval 'Foryou.Release.mint_api_key(\"terraform\")'` in the pod. Also readable from the FORYOU_API_KEY env var."
  default     = null
}

variable "organization_id" {
  type        = string
  description = "UUID of the owning foryou Organization (created in-app)."
  default     = "fd506a97-c49d-4fef-aa7a-68220af39f33"
}

variable "owner_user_id" {
  type        = string
  description = "foryou user UUID for keith.brings@noizu.com. Set on each Project at create to grant a project-level owner membership (required for authed detail/lists/signups access; org membership alone only grants listing visibility). Discover via GET /api/v1/management/users."
}

provider "foryou" {
  host    = var.foryou_host
  api_key = var.foryou_api_key
}
