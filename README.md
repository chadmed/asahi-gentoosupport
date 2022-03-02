# Apple Silicon Gentoo support files

A whole bunch of files to make Gentoo on your Apple Silicon device
a little nicer.

## What's included:
* An `asahi` overlay for Portage, which will contain packages patched by
the Asahi team to better support Apple Silicon devices (e.g. the kernel)
* Known good `.config` files for both GCC and Clang/LLVM toolchains (make sure you have merged and bootstrapped Clang/LLVM before trying to use the
latter!)
* A sane default `make.conf` to which you can add your own customisations
* A shell script to automate installing all of this stuff.

## Best way to use
1. Follow the Gentoo Handbook
2. Clone this repo on your first real boot (make sure you have a USB network
adapter if you're on one of the MacBooks)
3. Run `scripts/post-install.sh`
