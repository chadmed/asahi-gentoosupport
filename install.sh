#!/bin/bash

# Copyright 2022 James Calligeros <jcalligeros99@gmail.com>
# SPDX-License-Identifier: MIT

set -e


# TODO: create a make.conf
# install_makeconf() {
#         A="n"
#         echo "This will rename your make.conf to make.bak and replace it"
#         echo "with the default provided by this repo."
#         echo
#         read -p "Do you wish to do this (y/N)? " A
#         while [[ ${A} != "Y" || "y" || "N" || "n" ]]; do
#                 read -p "You must say 'y' or 'n'" A
#         done
#
#         if [[ ${A} == "n" || "N" ]]; then
#                 break
#         fi
#
#         if [[ ${A} == "y" || "Y" ]]; then
#                 mv /etc/portage/make.conf /etc/portage/make.bak
#                 cp resources/make.conf /etc/portage/make.conf
#                 echo "Your make.conf has been replaced."
#                 break
#         fi
# }


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
#         EMERGE_DEFAULT_OPTS="" \
#              emerge -qv m1n1
#         exec /bin/update-m1n1
#         echo "m1n1 has been installed."
        git clone --recursive --depth=1 https://github.com/AsahiLinux/m1n1/
        cd m1n1
        make -j$(nproc)
        cp build/m1n1.bin /usr/lib/asahi-boot/m1n1.bin
}


merge_kernel_sources() {
        C="y"
        echo "We provide a version of the Linux kernel with drivers and"
        echo "other patches required to support Apple Silicon devices."
        echo "Say y here unless you specifically want to test specific"
        echo "upstream versions."
        read -p "Do you wish to fetch the linux-asahi sources (Y/n)? " C
        while [[ ${C} != "Y" || "y" || "N" || "n" ]]; do
                read -p "You must say 'y' or 'n'" C
        done

        if [[ ${C} == "n" || "N" ]]; then
                break
        fi

        if [[ ${C} == "y" || "Y" ]]; then
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
        fi
}


set_kernconf() {
       D="y"
       echo "We can copy the Asahi Linux kernel config to /usr/src/linux"
       echo "for you to work off as a base rather than having to start with"
       echo "a blank slate. Say y here unless you really know what you are"
       echo "doing."
       read -p "Do you wish to use our kernel .config (Y/n)? " D
       while [[ ${D} != "Y" || "y" || "N" || "n" ]]; do
               read -p "You must say 'y' or 'n'" D
       done

       if [[ ${D} == "N" || "n" ]]; then
               break
       fi

       if [[ ${D} == "Y" || "y" ]]; then
               zcat /proc/config.gz > /usr/src/linux/.config
       fi
}


make_kernel() {
        F="Y"
        echo "Do you want us to build and install the kernel for you now?"
        echo "Say y here unless you have a non-standard boot chain,"
        echo "i.e. you are not using the default m1n1 + U-Boot + GRUB"
        echo "setup. This will take ~5-10 minutes. If you are using a laptop,"
        echo "you should plug it in before proceeding."
        echo
        read -p "Do you want to install the kernel now (Y/n)? " F
        while [[ ${F} != "Y" || "y" || "N" || "n" ]]; do
                read -p "You must say 'y' or 'n'" F
        done

        if [[ ${F} == "N" || "n" ]]; then
                break
        fi

        if [[ ${F} == "Y" || "y" ]]; then
                # Check if dracut is installed
                if [[ -n /usr/bin/dracut ]]; then
                EMERGE_DEFAULT_OPTS="" \
                     emerge -qv dracut
                fi

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
       fi
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

install_m1n1

merge_kernel_sources

# Only offer to make kernel if our .config is used
if [[ ${D} == "Y" || "y" ]]; then
        make_kernel
else
        echo "Asahi .config not used, skipping kernel build."
fi

install_fw

echo "This script will now exit. Continue setting up your machine as per the"
echo "Gentoo Handbook, skipping the steps related to setting up the kernel or"
echo "GRUB as these have been done for you."
