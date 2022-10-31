#!/bin/sh

# Adapted from asahi-scripts, which is (C) The Asahi Linux Contributors under the MIT license

if [ -e /vendorfw ]; then
    echo "Asahi: Vendor firmware was loaded by the bootloader"
    return 0
fi

if [ ! -e /proc/device-tree/chosen/asahi,efi-system-partition ]; then
    echo "Asahi: Missing asahi,efi-system-partition variable, firmware will not be loaded!"
    return 1
fi

# This needs to happen before udev loads so that the FW
# is available for devices
echo "Asahi: Triggering early load of NVMe modules..."
modprobe apple-mailbox
modprobe nvme-apple

for i in $(seq 0 50); do
    [ -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ] && break
    sleep 0.1
done

if [ ! -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ]; then
    err "Timed out waiting for NVMe device"
    return 1
fi

# If the above exists, hopefully the /dev device exists and this will work
echo "Asahi: Unpacking vendor firmware into initramfs..."

VENDORFW="/run/.system-efi/vendorfw/"

(
    . /usr/share/asahi-scripts/functions.sh
    mount_sys_esp /run/.system-efi
)

if [ ! -e "$VENDORFW/firmware.cpio" ]; then
    echo "Asahi: Vendor firmware not found in ESP."
    umount /run/.system-efi
    return 1
fi

( cd /; cpio -i < "$VENDORFW/firmware.cpio" )
echo "Asahi firmware unpacked successfully"
