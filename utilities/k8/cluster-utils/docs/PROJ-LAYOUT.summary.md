# Project Layout — Summary

```
cluster-utils/
├── bin/                            # cluster-* bash tools → ~/.local/bin
│   ├── cluster-status              #   tiered pod dashboard
│   ├── cluster-nodes               #   node capacity/placement
│   ├── cluster-resources           #   pod usage vs requests
│   ├── cluster-helm                #   helm release status
│   ├── cluster-layout              #   node/PVC/PV markdown layout
│   ├── cluster-manticore           #   manticore search dashboard
│   └── cluster-setup-telemetry     #   OTel+Fluent Bit VM installer
├── docs/                           # docs
│   ├── PROJ-ARCH.md
│   ├── PROJ-ARCH.summary.md
│   ├── PROJ-LAYOUT.md
│   ├── PROJ-LAYOUT.summary.md
│   └── arch/                       #   installation.md, shared-library.md
├── .gitignore
├── Makefile                        # make install
└── README.md
```
