#!/bin/busybox sh

# Mount filesystems
mount -t devtmpfs  none            /dev
mount -t proc      none            /proc
mount -t sysfs     none            /sys
mount -t tmpfs     none            /tmp
mount -t squashfs  /image.squashfs /new_root

# Pivot to Gentoo installer root
exec switch_root /newroot /sbin/init
