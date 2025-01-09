#!/bin/bash

# Copyright 2022 James Calligeros <jcalligeros99@gmail.com>
# SPDX-License-Identifier: MIT

set -e

install_overlay() {
        echo "Installing the Asahi Overlay. For more information, visit"
        echo "https://github.com/chadmed/asahi-overlay/"
        echo

        emerge -q eselect-repository
        eselect repository enable asahi
        emaint sync -r asahi
        echo "The Asahi overlay has been installed."
}

install_meta() {
        echo "We will now install the Asahi metapackage with some sane"
        echo "defaults to get you started. This step will:"
        echo "  * Mask media-libs/mesa::gentoo"
        echo "  * Emerge rust-bin (you can switch to the compiled rust later)"
        echo "  * Create /etc/portage/package.use/asahi and set:"
        echo "          sys-apps/asahi-meta kernel -sources -audio"
        echo "     The audio USE flag is disabled to reduce the compilation time"
        echo "     required to reach a bootable state."
        echo "     If you are plan to use this device with audio support, please"
        echo "     delete '-audio' from this file and emerge -1 asahi-meta BEFORE"
        echo "     emerging your DE/WM."
        echo "  * Add VIDEO_CARDS=\"asahi\" to /etc/portage/make.conf"
        echo "  * Emerge the Asahi metapackage"
        echo "  * Unpack the Asahi firmware"
        echo "  * Update m1n1 and U-Boot"
        read -sp "Press Enter to continue..."

        [ ! -d /etc/portage/package.mask ] && mkdir /etc/portage/package.mask
        cp resources/package.mask /etc/portage/package.mask/asahi
        [ ! -d /etc/portage/package.use ] && mkdir /etc/portage/package.use
        cp resources/package.use /etc/portage/package.use/asahi
        [ ! -d /etc/portage/package.license ] && mkdir /etc/portage/package.license
        echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" > /etc/portage/package.license/firmware
	echo "VIDEO_CARDS=\"asahi\"" >> /etc/portage/make.conf

        emerge -q1 dev-lang/rust-bin
        emerge -q sys-apps/asahi-meta virtual/dist-kernel:asahi sys-kernel/linux-firmware
        asahi-fwupdate
        update-m1n1
}

install_grub() {
        echo "Installing GRUB."
        echo "GRUB_PLATFORMS=\"efi-64\"" >> /etc/portage/make.conf
        emerge -q grub:2
        grub-install --boot-directory=/boot/ --efi-directory=/boot/ --removable
        grub-mkconfig -o /boot/grub/grub.cfg
        echo "GRUB has been installed."
}


if [[ $(whoami) != "root" ]]; then
        echo "You must run this script as root."
        exit 1
fi

if [[ ! -d /boot/vendorfw ]]; then
        echo "We use ESP-as-boot. Please mount the Asahi ESP to /boot and"
        echo "before continuing. This is absolutely essential for the system"
        echo "to function correctly."
        exit 1
fi


echo "This script automates the setup and configuration of Apple Silicon"
echo "specific tooling for Gentoo Linux. Please mount the ESP to /boot."
echo
echo "NOTE: This script will install linux-firmware automatically. It is not"
echo "possible to run these machines properly without binary blobs. Please make"
echo "sure you understand this, and agree to the linux-fw-redistributable and"
echo "no-source-code licenses before continuing."
echo
read -sp "Press Enter to continue..."


install_overlay

install_meta

install_grub

echo "This script will now exit. Continue setting up your machine as per the"
echo "Gentoo Handbook, skipping the steps related to setting up the kernel or"
echo "GRUB as these have been done for you. Don't forget to add /boot to your"
echo "fstab!"
