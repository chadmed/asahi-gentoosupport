#!/bin/sh

echo "Asahi: Copying vendor firmware to tmpfs under root filesystem..."
mount -o remount,rw /sysroot
mkdir -p /sysroot/lib/firmware/vendor
mount -t tmpfs vendorfw /sysroot/lib/firmware/vendor
cp -r /vendorfw/* /vendorfw/.vendorfw.manifest /sysroot/lib/firmware/vendor
