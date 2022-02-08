Automating scripts to setup an operating system

# Sway

Archlinux minimalistic setup of Sway Windows Manager.

Since Sway WM uses Wayland bindings, make sure your video adapter is Wayland
compatible.

## Content
- sway1.sh - Prepare a hard drive. It uses luks over lvm to enrypt a disk
    with a password.
- sway2.sh - Install a system. It installs very minimal set of tools, such as,
    alacritty, firefox, openssh and git to make your setup being ready for the
    further configuration.

## Install

- Init a system from memory via archlinux usb stick.
- `pacman -Syy`
- `pacman -S git`
- `git clone https://github.com/elijahdanko/distro-init.git`
- `cd distro-init`
- `bash sway1.sh`
-  When sway1.sh installation completed by copy sway2.sh to the mounted system,
   then run `bash sway2.sh`
