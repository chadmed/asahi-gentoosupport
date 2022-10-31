#!/bin/sh

# only install if asked for
check() {
    return 255
}

# depend on bash
depends() {
    echo bash
    return 0
}

# put our stuff in the initramfs
install() {

    inst_multiple -o comm /usr/share/asahi-scripts/* cut dirname seq tar

    # Run hook before udev to copy firmware
    inst_hook pre-mount 99 "$moddir/copy-firmware.sh"

    # Now run a hook just before we pivot to the root
    inst_hook pre-pivot 99 "$moddir/place-firmware.sh"

}
