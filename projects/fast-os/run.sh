#!/usr/bin/env bash
# Deprecated: use `make run` (QEMU CLI) or `make image` (UTM). See Makefile.
exec make -C "$(dirname "$0")" run
