#!/bin/sh
# SPDX-License-Identifier: MIT

set -e

BOOT_PART="/boot"
EFI_PART="/boot/efi"
GRUB_DIR="$BOOT_PART/grub"
CONFIG="/boot/grub/grub.cfg"
TARGET="$EFI_PART/EFI/BOOT/BOOTAA64.EFI"
MODULES="ext2 part_gpt search"

[ -e /etc/default/update-grub ] && source /etc/default/update-grub

uuid="$(grub-probe "$BOOT_PART" -t fs_uuid)"
part="$(grub-probe "$BOOT_PART" -t drive | sed -e 's/(.*,/hd0,/' | tr -d ')')"

if [ -z "$uuid" ]; then
    echo "Error: Unable to determine root filesystem UUID"
    exit 1
fi

echo "UUID: $uuid"
echo "Partition: $part"

cat > /tmp/grub-core.cfg <<EOF
search.fs_uuid $uuid root $part
set prefix=(\$root)'/boot/grub'
EOF

echo "Generating GRUB image..."
grub-mkimage \
    --directory '/usr/lib/grub/arm64-efi' \
    -c /tmp/grub-core.cfg \
    --prefix "$part/boot/grub" \
    --output "$GRUB_DIR"/arm64-efi/core.efi \
    --format arm64-efi \
    --compression auto \
    $MODULES

cp "$GRUB_DIR"/arm64-efi/core.efi "$TARGET"

grub-mkconfig -o "$CONFIG"
