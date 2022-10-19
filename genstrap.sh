#!/bin/bash

set -e

cleanup() {
    echo "Cleaning up...."
    echo
    rm -rf /mnt/temp/
    rm -rf squashfs-root
    rm -rf image.squashfs
    rm -rf new.squashfs
    rm -rf overlay
    rm -rf squashtree
}

if [[ $(whoami) != "root" ]]; then
    echo "This script must be run as root. Type your password"
    echo "when prompted."
    sudo ./genstrap.sh
    exit 0

fi

echo "This script will bootstrap an initramfs for installing Gentoo on"
echo "Apple Silicon machines. It must be run from an Asahi Linux install."
echo
echo "Please ensure that the latest Gentoo arm64 minimal install"
echo "image is located in this directory and named install.iso before"
echo "continuing."
echo
read -sp "Press Enter to continue."
echo

cleanup

echo "Installing dependencies..."
pacman -S --needed squashfs-tools dracut cpio parted

echo "Extracting squashfs..."
bsdtar -xf install.iso --include image.squashfs

echo "Creating temporary mount..."
echo
mkdir /mnt/temp
modprobe brd rd_nr=1 rd_size=923600

if [[ $? -ne 0 ]]; then
    echo "ERROR: could not create ram block device. Installing asahi-dev"
    echo "kernel."
    sed -i 's/asahi/asahi-dev/' /etc/pacman.conf
    pacman -Syu
    echo "The asahi-dev kernel has been installed. Please reboot the machine and"
    echo "run this script again."
    exit 1
fi

parted -sf /dev/ram0 mklabel gpt
parted -sf /dev/ram0 "mkpart root 0 -1"
mkfs.ext4 /dev/ram0p1
mount /dev/ram0p1 /mnt/temp

echo "Unsquashing Gentoo live environment."
echo
unsquashfs -q image.squashfs

echo "Setting up Gentoo live environment for Apple Silicon..."
echo
cd squashfs-root
rm -rf lib/firmware/{iwlwifi*,qcom,amd*,advansys,intel,nvidia,rtlwifi}
rm -rf lib/firmare/{rockchip,myr*,mwl*,atmel,bnx*,3com,ti*,ql*}
rm -rf lib/modules/*gentoo*
cp -r /lib/modules/$(uname -r) lib/modules/

depmod -a --basedir=. $(uname -r)

cp -r /lib/firmware/brcm/. lib/firmware/brcm/.
# The squashfs doesn't log in automatically for some reason?
echo "agetty_options=\"--autologin root\"" >> etc/conf.d/agetty
sed -i 's/\<agetty\>/& --autologin root/g' etc/inittab


echo "Creating live image..."
echo
cd ..
cp -r squashfs-root/* /mnt/temp/
umount /dev/ram0p1
mkdir -p squashtree/LiveOS
dd if=/dev/ram0p1 of=squashtree/LiveOS/rootfs.img
mksquashfs squashtree new.squashfs -quiet

echo "Setting up initramfs..."
mkdir -p overlay \
        overlay/etc/cmdline.d \
        overlay/mnt/efi
cp new.squashfs overlay/squash.img
echo "root=live:/squash.img ro console=tty0 init=/sbin/init" \
     > overlay/etc/cmdline.d/01-default.conf

dracut --force \
    --quiet \
    --kver $(uname -r) \
    --add-drivers "nvme-apple" \
    --add-drivers "squashfs" \
    --add-drivers "apple-dart" \
    --add-drivers "brcmfmac" \
    --add "dmsquash-live" \
    --filesystems "squashfs ext4" \
    --include overlay / \
    ./bootstrap_image.img


echo "Setting up initramfs and GRUB..."

mv bootstrap_image.img /boot/initramfs-gentoo-live.img
cat resources/init_grub >> /boot/grub/grub.cfg

cleanup
modprobe -r brd

echo "When rebooting your system, select Gentoo Live Install environment from"
echo "the GRUB menu to boot into the Gentoo LiveCD."
