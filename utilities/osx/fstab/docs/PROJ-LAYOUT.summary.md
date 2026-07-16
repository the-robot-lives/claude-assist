# fstab-mounter — Layout Summary

```
fstab-mounter/
├── fstab-remount                          # Mount script
├── com.keithbrings.fstab-remount.plist    # LaunchDaemon plist
├── osx-fstab.stub                         # Config template
├── mount-ntfs-rw.sh                       # One-off NTFS rw mount helper
├── Makefile                               # Installer
├── Bulk/                                  # Empty placeholder dir
├── .gitignore                             # Ignore rules
└── docs/                                  # Documentation
```

Installs to: `/usr/local/bin/fstab-remount`, `/Library/LaunchDaemons/`, `/etc/osx-fstab`.
