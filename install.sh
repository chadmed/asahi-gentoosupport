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


install_distkernel() {
        echo "We will now install the Asahi dist-kernel for you."
        echo
        read -sp "Press Enter to continue..."
        echo

        emerge -q sys-kernel/asahi-kernel virtual/dist-kernel

        # We need to rebuild GRUB
        grub-install --removable --efi-directory=/boot --boot-directory=/boot
        grub-mkconfig -o /boot/grub/grub.cfg
}


install_fw() {
        echo "We will now install the Apple Silicon firmware from the ESP."
        echo
        echo "Be sure to install and configure whatever userspace network/WiFi management"
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

        asahi-fwupdate
        echo "Firmware installed."
        read -sp "Press Enter to continue..."
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

install_uboot

install_grub

install_distkernel

install_m1n1

install_fw

echo "This script will now exit. Continue setting up your machine as per the"
echo "Gentoo Handbook, skipping the steps related to setting up the kernel or"
echo "GRUB as these have been done for you. Don't forget to add /boot to your"
echo "fstab!"
