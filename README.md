# Apple Silicon Gentoo install helper

This repo makes it possible to bootstrap a vanilla Gentoo environment on
Apple Silicon hardware.

## Quickstart guide
1. Use the Asahi Installer to install the Asahi Linux Minimal environment
2. Download the latest Gentoo arm64 minimal installation CD image
3. Clone this repo
4. Copy the Gentoo CD image to this repo and rename it `install.iso`
5. Create a bootstrap initramfs by running `genstrap.sh`
6. Reboot the machine. The Gentoo install environment will automatically load
7. Format the Asahi Linux root partition as you see fit (**SEE THE NOTES**)
8. Follow the Handbook up to and including chrooting into the new filesystem
9. Mount the EFI System Partition created by Asahi to `/boot/efi`
10. Clone this repo somewhere on the filesystem and run `install.sh`
11. Reboot into your fresh new Gentoo install.

## Important notes
It is absolutely imperative that you **DO NOT** alter **any** other partition
on the system, including the EFI System Partition set up by Asahi Linux. You
are free to do anything you wish to the partition that was previously your
Asahi Linux **root** filesystem, such as shrinking it to add some swap space,
but never, **ever** delete any APFS partition or the Asahi EFI System partition.
You have been warned...
