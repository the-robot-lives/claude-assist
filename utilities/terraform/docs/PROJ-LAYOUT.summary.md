# Project Layout Summary — utilities/terraform

Grouping directory for Terraform DevOps utilities; children carry their own docs.

```
terraform/
├── terraform-utils/            # tf-plan-all + migrate-tfstate CLI package
│   └── docs/                   #   child PROJ-LAYOUT/PROJ-ARCH summaries
└── Makefile                    # SUBDIRS fan-out via ../mk/subdirs.mk
```

Child docs: [terraform-utils layout](../terraform-utils/docs/PROJ-LAYOUT.summary.md) · [terraform-utils architecture](../terraform-utils/docs/PROJ-ARCH.summary.md)
