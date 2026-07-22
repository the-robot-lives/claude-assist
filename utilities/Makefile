SUBDIRS := agent shell k8 terraform database colo start-app-scaffold linux osx
SUBDIRS_DEFAULT := $(filter-out osx linux,$(SUBDIRS))
SUBDIR_TARGETS := build compile test clean
SUBDIR_DESCRIPTION := Utility groups

.PHONY: install install-utilities _utilities_install

_utilities_install:
	@set -e; \
	for dir in $(SUBDIRS_DEFAULT); do \
		target=install; \
		if [ -f "$$dir/Makefile" ]; then \
			echo "--- $$dir ($@ -> $$target) ---"; \
			$(MAKE) -C "$$dir" $$target; \
		else \
			echo "--- $$dir (missing $$dir/Makefile) ---"; \
		fi; \
	done

install: _utilities_install

install-utilities:
	$(MAKE) install

include mk/subdirs.mk
