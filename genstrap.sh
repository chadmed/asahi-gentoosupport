#!/bin/bash

set -e

echo "This script will bootstrap an initramfs for installing Gentoo on"
echo "Apple Silicon machines. It must be run from an Asahi Linux install."

echo "Please ensure that the latest Gentoo arm64 minimal install"
echo "image is located in this directory and named install.iso before"
echo "continuing."
read -sp "Press Enter to continue."


echo "Extracting squashfs..."
bsdtar -xf install.iso --include image.squashfs

echo "Creating bootstrap initramfs..."
mkdir root
cd root
mkdir -p bin dev etc lib mnt proc sbin sys tmp var new_root
# TODO: BusyBox site is down!
curl -L https://busybox.net/downloads/path-to-latest-aarch64-bb -o bin/busybox
cp ../image.squashfs .
cp -r /lib/firmware lib/.
cp -r /lib/modules lib/.
cp ../resources/initramfs_init.sh init
chmod x+ init
find . | cpio -ov --format=newc | zstdmt > ../boostrap_image.img
cd ..

echo "WARNING: This step will relocate the default Asahi Linux initramfs"
echo "to /boot/asahi-initramfs.img. If something goes wrong, you can return"
echo "to Asahi Linux by editing the GRUB boot options accordingly. You will"
echo "be asked for your password for this next step."
read -sp "Press Enter to continue."

sudo mv /boot/initramfs-linux-asahi.img /boot/asahi-initramfs.img
sudo cp boostrap_image.img /boot/initramfs-linux-asahi.img

echo "The next time you boot this system, it will enter a vanilla Gentoo install"
echo "environment, from which you can install Gentoo as you would on any other"
echo "machine. Once you have chrooted into your new root partition, clone this"
echo "repo again and run install.sh to be guided through setting up valid"
echo "kernel, GRUB, m1n1 and firmware configurations."
