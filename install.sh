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
        emerge -q u-boot
        echo "U-Boot has been installed."
}


install_grub() {
        echo "Installing GRUB."
        echo "GRUB_PLATFORMS=\"efi-64\"" >> /etc/portage/make.conf
        emerge -q grub:2
        echo "GRUB has been installed."
}


install_m1n1() {
        echo "Installing m1n1."
        emerge -qv m1n1
        update-m1n1
        echo "m1n1 has been installed."
}


merge_kernel_sources() {
        # Install a package.use for the kernel
        if [[ ! -d /etc/portage/package.use ]]; then
                mkdir -p /etc/portage/package.use
        fi
        echo "sys-kernel/asahi-sources symlink" >> /etc/portage/package.use/kernel
        emerge -qv asahi-sources
        echo "The patched kernel sources are now available in"
        echo "/usr/src/linux."
}


make_kernel() {
        echo "We are going to install a known-good kernel for you now. You"
        echo "can edit this at any time after the install procedure has finished."
        echo "In fact, you should edit it once you've booted in to the filesystem."
        echo
        read -sp "Press Enter to continue..."
        echo
        # Check if genkernel is installed
        if [[ ! -f /usr/bin/genkernel ]]; then
                echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license
                emerge -qv genkernel
        fi
        echo "sys-apps/kmod zstd" >> /etc/portage/package.use/kernel
        emerge -qv kmod
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
        make -C /usr/src/linux install

        # Build initramfs (takes longer than dracut, but works)
        genkernel \
            --kernel-config=/usr/src/linux/.config \
            --all-ramdisk-modules \
            initramfs

        # We need to rebuild GRUB
        grub-install --removable --efi-directory=/boot/efi --boot-directory=/boot
        grub-mkconfig -o /boot/grub/grub.cfg
}


install_fw() {
        echo "We will now install the Apple Silicon firmware to /lib/firmware."
        echo
        echo "Be sure to install whatever userspace network/WiFi management"
        echo "software you want before you reboot."
        read -sp "Press Enter to continue..."
        echo
        echo "Installing firmware management scripts"
        emerge -q asahi-firmware
        echo
        echo "Extracting firmware..."

        if [[ ! -d /lib/firmware ]]; then
                echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license
                emerge -qv linux-firmware
        fi

        /usr/sbin/asahi-fwextract
        echo "Firmware installed."
        read -sp "Press Enter to continue..."
}

if [[ $(whoami) != "root" ]]; then
        echo "You must run this script as root."
        exit 1
fi

if [[ ! -d /boot/efi/vendorfw ]]; then
        echo "You must mount the Asahi EFI System Partition to /boot/efi."
        echo "This is absolutely necessary for the proper functioning of the"
        echo "system. Please mount the ESP at /boot/efi and add it to your"
        echo "fstab before continuing."
        exit 1
fi


echo "This script automates the setup and configuration of Apple Silicon"
echo "specific tooling. Please ensure that /boot is mounted where you want, and"
echo "the Asahi EFI System Partition is mounted to /boot/efi."
echo
echo "NOTE: This script will install linux-firmware automatically. It is not"
echo "possible to run these machines properly without binary blobs. Please make"
echo "sure you understand this, and agree to the linux-fw-redistributable and"
echo "no-source-code licenses before continuing."
echo
read -sp "Press Enter to continue..."


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
