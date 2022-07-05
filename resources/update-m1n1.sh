#!/bin/sh
set -e

m1n1_dir="/boot/efi/m1n1"
src=/usr/lib/asahi-boot

target="$m1n1_dir/boot.bin"
if [ ! -z "$1" ]; then
	target="$1"
fi

if [ ! -e "$m1n1_dir" ]; then
	echo "$m1n1_dir does not exist, is /boot/efi mounted?" 1>&2
	exit 1
fi

DTBS=/usr/src/linux/arch/arm64/boot/dts/apple/*.dtb

cat "$src/m1n1.bin" $DTBS \
    <(gzip -c "$src/u-boot-nodtb.bin") \
    >"${target}.new"
mv -f "${target}.new" "$target"

echo "m1n1 updated at ${target}"
