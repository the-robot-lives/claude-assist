PLIST      := com.keithbrings.fstab-remount.plist
PLIST_DST  := /Library/LaunchDaemons/$(PLIST)
BIN_SRC    := fstab-remount
BIN_DST    := /usr/local/bin/fstab-remount
FSTAB_STUB := osx-fstab.stub
FSTAB_DST  := /etc/osx-fstab
SUDO       ?= sudo

.PHONY: install uninstall status logs install-ntfs check-ntfs

install:
	@echo "==> Installing fstab-remount"
	@if $(SUDO) -n true 2>/dev/null; then \
		$(SUDO) install -m 755 $(BIN_SRC) $(BIN_DST); \
		$(SUDO) install -m 644 $(PLIST) $(PLIST_DST); \
		if [ ! -f $(FSTAB_DST) ]; then \
			echo "==> Creating stub $(FSTAB_DST)"; \
			$(SUDO) install -m 644 $(FSTAB_STUB) $(FSTAB_DST); \
		else \
			echo "==> $(FSTAB_DST) already exists — skipping"; \
		fi; \
		$(SUDO) launchctl bootout system/$(basename $(PLIST) .plist) 2>/dev/null || true; \
		$(SUDO) launchctl bootstrap system $(PLIST_DST); \
		echo "==> Done. Edit $(FSTAB_DST) then reboot or run: sudo launchctl kickstart system/com.keithbrings.fstab-remount"; \
	else \
		echo "==> Skipping fstab-remount: noninteractive sudo is unavailable"; \
		echo "    Run manually when ready: cd $(CURDIR) && sudo make install"; \
	fi

uninstall:
	@echo "==> Uninstalling fstab-remount"
	$(SUDO) launchctl bootout system/com.keithbrings.fstab-remount 2>/dev/null || true
	$(SUDO) rm -f $(BIN_DST) $(PLIST_DST)
	@echo "==> Removed. $(FSTAB_DST) left in place."

status:
	@$(SUDO) launchctl print system/com.keithbrings.fstab-remount 2>/dev/null || echo "Not loaded"

logs:
	@$(SUDO) tail -50 /var/log/fstab-remount.log

install-ntfs:
	@echo "==> Installing NTFS read-write support (fuse-t + ntfs-3g)"
	@if ! brew list --cask fuse-t &>/dev/null; then \
		echo "==> Installing FUSE-T (kext-less FUSE)"; \
		brew install --cask fuse-t; \
	else \
		echo "==> FUSE-T already installed"; \
	fi
	@if ! command -v ntfs-3g &>/dev/null; then \
		echo "==> Installing ntfs-3g"; \
		brew install ntfs-3g; \
	else \
		echo "==> ntfs-3g already installed"; \
	fi
	@echo "==> NTFS read-write support ready"
	@echo "    Add ntfs entries to $(FSTAB_DST) and reboot or run:"
	@echo "    sudo launchctl kickstart system/com.keithbrings.fstab-remount"

check-ntfs:
	@echo "FUSE-T:  $$(brew list --cask fuse-t &>/dev/null && echo 'installed' || echo 'NOT installed')"
	@echo "ntfs-3g: $$(command -v ntfs-3g &>/dev/null && echo "$$(ntfs-3g --version 2>&1 | head -1)" || echo 'NOT installed')"
