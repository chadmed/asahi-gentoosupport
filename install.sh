#!/bin/bash

# Copyright 2022 James Calligeros <jcalligeros99@gmail.com>
# SPDX-License-Identifier: MIT

set -e

install_overlay() {
        echo "Installing the Asahi Overlay. For more information, visit"
        echo "https://github.com/chadmed/asahi-overlay/"
        echo

        cp resources/repo.conf /etc/portage/repos.conf/asahi.conf
        emaint sync -r asahi
        echo "The Asahi overlay has been installed."
}


install_uboot() {
        echo "Installing U-Boot."
        EMERGE_DEFAULT_OPTS="" \
             emerge -qv u-boot
        echo "U-Boot has been installed."
}


install_grub() {
        echo "Installing GRUB."
        USE="grub_platforms_efi-64" \
                EMERGE_DEFAULT_OPTS="" \
                emerge -qv grub:2
        echo "GRUB has been installed."
}


install_m1n1() {
         echo "Installing m1n1."
         cp resources/update-m1n1.sh /bin/update-m1n1
         chmod a+x /bin/update-m1n1
         if [[ -n /boot/efi ]]; then
                mkdir /boot/efi
        fi
        mount /dev/nvme0n1p4 /boot/efi
         EMERGE_DEFAULT_OPTS="" \
              emerge -qv m1n1
         exec /bin/update-m1n1
         echo "m1n1 has been installed."
}


merge_kernel_sources() {
        # Install a package.use for the kernel
        if [[ -n /etc/portage/package.use ]]; then
                mkdir -p /etc/portage/package.use
        fi
        cp resources/kerneluse /etc/portage/package.use/asahi-sources
        # Override the user's default opts in make.conf
        # so they aren't asked again if they want to merge
        EMERGE_DEFAULT_OPTS="" \
                emerge -qv asahi-sources
        echo "The patched kernel sources are now available in"
        echo "/usr/src/linux."
}


make_kernel() {
        echo "We are going to install a known-good kernel for you now. You"
        echo "can edit this at any time after the install procedure has finished."
        echo
        read -sp "Press Enter to continue..."
        # Check if dracut is installed
        EMERGE_DEFAULT_OPTS="" \
                emerge -qv dracut

        zcat /proc/config.gz > /usr/src/linux/.config

        make -C /usr/src/linux -j $(nproc)
        KERNVER=$(make -C /usr/src/linux -s kernelrelease)

        make -C /usr/src/linux modules_install
        # Gentoo's GRUB expects Image and the initramfs to be
        # in pairs with the same release tag, with the tag
        # -linux taking precedence over all others. If
        # a kernel already exists with that tag, we need to
        # move it so that our kernel and initramfs become the
        # default booted
        if [[ -e /boot/vmlinu{x,z}-linux ]]; then
                mv /boot/vmlinu{x,z}-linux /boot/vmlinu{x,z}-old
        fi
        if [[ -e /boot/initramfs-linux.img ]]; then
                mv /boot/initramfs-linux.img /boot/initramfs-old.img
        fi
        cp /usr/src/linux/arch/arm64/boot/Image /boot/vmlinux-linux

        # We must manually ensure that dracut finds the kernel
        # and nvme-apple
        dracut \
                --force \
                --quiet \
                --add-drivers="nvme-apple" \
                --kver ${KERNVER} \
                --compress gzip \
                /boot/initramfs-linux.img

        # We need to rebuild GRUB
        cp resources/update-grub.sh /bin/update-grub
        chmod a+x /bin/update-grub
        exec /bin/update-grub
}


install_fw() {
        echo "We will now install the Apple Silicon firmware to /lib/firmware."
        echo
        echo "If you have not already merged sys-firmware/linux-firmware,"
        echo "please do so now before continuing."
        echo
        echo "Be sure to install whatever userspace network/WiFi management"
        echo "software you want before you reboot."
        read -sp "Press Enter to continue..."
        echo
        echo "Extracting firmware"

        while [[ -n /boot/efi/linux-firmware.tar ]]; do
                echo "linux-firmware.tar not found on /boot/efi."
                echo "Please ensure the EFI System Partition set up"
                echo "by the Asahi Installer is mounted at /boot/efi."
                echo
                read -sp "Press Enter to try again..."
        done

        cp resources/update-vendor-fw.sh /bin/update-vendor-fw
        chmod a+x /bin/update-vendor-fw
        exec /bin/update-vendor-fw
        echo "Firmware installed."
        read -sp "Press Enter to continue..."


if [[ whoami != "root" ]]; then
        echo "You must run this script as root."
        exit
fi

echo "This script automates the setup and configuration of Apple Silicon"
echo "specific tooling. Please ensure that /boot is mounted where you want, and"
echo "the Asahi EFI System Partition is mounted to /boot/efi."
read -sp "Press Enter to continue..."

}

# install_makeconf()

install_overlay

install_uboot

install_grub

merge_kernel_sources

make_kernel

install_m1n1

install_fw

echo "This script will now exit. Continue setting up your machine as per the"
echo "Gentoo Handbook, skipping the steps related to setting up the kernel or"
echo "GRUB as these have been done for you."
