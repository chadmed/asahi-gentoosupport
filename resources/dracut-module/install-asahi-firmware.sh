#!/bin/sh
# SPDX-License-Identifier: MIT

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

info ":: Asahi: Installing vendor firmware to root filesystem..."
if [ ! -d /sysroot/lib/firmware/vendor ]; then
    warn ":: Asahi: Vendor firmware directory missing on the root filesystem!"
    return 1
fi
mount -t tmpfs -o mode=0755 vendorfw /sysroot/lib/firmware/vendor
cp -pr /vendorfw/* /vendorfw/.vendorfw.manifest /sysroot/lib/firmware/vendor
