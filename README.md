# Apple Silicon Gentoo install helper

This repo makes it possible to bootstrap a vanilla Gentoo environment on
Apple Silicon hardware.


## Installing
Please familiarise yourself with the documentation at the Asahi Linux Wiki,
most importantly [this page](https://github.com/AsahiLinux/docs/wiki/Installing-Gentoo-with-LiveCD),
which gives specific instructions on how to use this repo correctly.


## Important note!
It is absolutely imperative that you **DO NOT** alter **any** other partition
on the system, including the EFI System Partition set up by Asahi Linux. You
are free to do anything you wish to the partition that was previously your
Asahi Linux **root** filesystem, such as shrinking it to add some swap space,
but never, **ever** delete any APFS partition or the Asahi EFI System partition.
You have been warned...
