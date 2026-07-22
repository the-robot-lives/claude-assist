terraform {
  required_version = ">= 1.10"

  required_providers {
    foryou = {
      source  = "noizu/foryou"
      version = "0.1.0"
    }
  }
}

provider "foryou" {
  host    = var.foryou_host
  api_key = var.foryou_api_token
}
