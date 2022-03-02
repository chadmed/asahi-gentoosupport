#!/bin/bash

# Copyright 2022 James Calligeros <jcalligeros99@gmail.com>
# SPDX-License-Identifier: MIT

set -e

install_makeconf() {
        A="n"
        echo "This will rename your make.conf to make.bak and replace it"
        echo "with the default provided by this repo."
        echo
        read -p "Do you wish to do this (y/N)? " A
        while [[ ${A} != "Y" || "y" || "N" || "n" ]]; do
                read -p "You must say 'y' or 'n'" A
        done

        if [[ ${A} == "n" || "N" ]]; then
                break
        fi

        if [[ ${A} == "y" || "Y" ]]; then
                mv /etc/portage/make.conf /etc/portage/make.bak
                cp resources/make.conf /etc/portage/make.conf
                echo "Your make.conf has been replaced."
                break
        fi
}


install_overlay() {
        B="y"
        echo "It is strongly recommended that you make use of the Asahi"
        echo "overlay to ensure any packages you install have been patched"
        echo "for Apple Silicon devices."
        echo "For more information, visit"
        echo "https://github.com/chadmed/asahi-overlay/"
        echo
        read -p "Do you wish to install the Asahi overlay (Y/n)? " B
        while [[ ${B} != "Y" || "y" || "N" || "n" ]]; do
                read -p "You must say 'y' or 'n'" B
        done

        if [[ ${B} == "n" || "N" ]]; then
                break
        fi

        if [[ ${B} == "y" || "Y" ]]; then
                cp resources/repo.conf /etc/portage/repos.conf/asahi.conf
                exec emaint sync -r asahi
                echo "The Asahi overlay has been installed."
        fi
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
                exec EMERGE_DEFAULT_OPTS="" \
                     emerge -qv asahi-sources
                echo "The patched kernel sources are now available in"
                echo "/usr/src/linux."
        fi
}


set_kernconf() {
        D="y"
        echo "We also provide a default kernel configuration that will"
        echo "work for all devices. We can install this for you now."
        echo "Say y here unless you really know what you are doing."
        echo "Even if you know what you are doing, our default config"
        echo "is a known-good starting point you can use for your own"
        echo "customisations."
        echo
        read -p "Do you wish to use our kernel .config (Y/n)? " D
        while [[ ${D} != "Y" || "y" || "N" || "n" ]]; do
                read -p "You must say 'y' or 'n'" D
        done

        if [[ ${D} == "N" || "n" ]]; then
                break
        fi

        if [[ ${D} == "Y" || "y" ]]; then
                E="1"
                echo "Available .config variants:"
                echo "(1) gcc"
                echo "(2) clang w/ ThinLTO"
                read -p "Make your selection (default: 1): " E
                while [[ ${E} != "1" || "2" ]]; do
                        read -p "You must say '1' or '2'" E
                done
                if [[ ${E} == "1" ]]; then
                        cp resources/gccconf /usr/src/linux/.config
                        echo "GCC .config installed to /usr/src/linux/"
                fi
                if [[ ${E} == "2" ]]; then
                        cp resources/clangconf /usr/src/linux/.config
                        echo "Clang .config installed to /usr/src/linux"
                fi
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
                exec EMERGE_DEFAULT_OPTS="" \
                     emerge -qv dracut
                fi

                cd /usr/src/linux
                # If user picked clang config, add LLVM and LLVM_IAS to make
                if [[ ${E} == "2" ]]; then
                        exec make LLVM=1 LLVM_IAS=1 -j $(nproc)
                else
                        exec make -j $(nproc)
                fi
                # Place our dracut conf
                mv /etc/dracut.conf /etc/dracut.bak
                cp resources/dracut.conf /etc/dracut.conf

                exec make modules_install
                exec make install
                exec dracut
                # We need to ensure the GRUB version
                exec grub-mkconfig -o /boot/grub/grub.cfg
        fi
}

install_plymouth() {
        echo "Normally, this is where we would install Plymouth and"
        echo "the Asahi splash screen. However, since Plymouth requires"
        echo "kernel modesetting, which itself requires a proper display"
        echo "controller driver, there is no point in installing it at"
        echo "this stage. Once the DCP driver has been merged into"
        echo "linux-asahi, we will install Plymouth too."
        echo
        read -sp "Press Enter to continue..."
}


if [[ whoami != "root" ]]; then
        echo "You must run this script as root."
        exit
fi

echo "This script will set up your system as per the readme."
read -sp "Press Enter to continue..."


install_makeconf()

install_overlay()

# Only ask about asahi-sources if the overlay was installed
if [[ ${B} == "y" || "Y" ]]; then
        merge_kernel_sources()
fi

# Only offer to make kernel if our .config is used
if [[ ${D} == "Y" || "y" ]]; then
        make_kernel()
fi

install_plymouth()

echo "We will now reboot your machine to apply the changes you have made."
echo "If you have anything open, please make sure you save it before"
echo "continuing."
echo
read -sp "Press Enter to reboot..."
exec reboot
