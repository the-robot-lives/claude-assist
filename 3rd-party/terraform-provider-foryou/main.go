// Package main is the entrypoint for the noizu/foryou Terraform provider.
package main

import (
	"context"
	"flag"
	"log"

	foryou "github.com/noizu/terraform-provider-foryou/foryou"
	"github.com/hashicorp/terraform-plugin-framework/providerserver"
)

// version is overridden by goreleaser; "dev" for local builds.
var version = "dev"

func main() {
	var debug bool

	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with debugger support")
	flag.Parse()

	err := providerserver.Serve(context.Background(), foryou.New(version), providerserver.ServeOpts{
		Address: "registry.terraform.io/noizu/foryou",
		Debug:   debug,
	})
	if err != nil {
		log.Fatal(err.Error())
	}
}
