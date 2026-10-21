# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos

SHELL_FILES := bin/mycustos $(shell find bin/modules -type f -name '*.sh')

.PHONY: all check syntax lint test

all: check

check: syntax lint test

syntax:
	@for f in $(SHELL_FILES); do bash -n "$$f" || exit 1; done
	@echo "syntax: OK"

lint:
	shellcheck -x -s bash $(SHELL_FILES)
	@echo "shellcheck: OK"

test:
	bats tests
