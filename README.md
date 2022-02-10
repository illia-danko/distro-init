Automating scripts to setup an operating system

Q: If disaster happened, how fast you can recover the system?
A: Me: from absolute zero to the complete functional system - 20 minutes (assume
having USB live sticker).

How?

- step1: install operating system from script (all the repo about).
- step2 (optional): download from some very secret place SSH secrets.
- step3: initialize the system via dotfiles script.

# Sway

Archlinux minimalistic setup of Sway Windows Manager.

Since Sway WM uses Wayland bindings, make sure your video adapter is
Wayland compatible.

## Content
- sway1.sh - Prepare a hard drive. It uses luks over lvm to enrypt a disk
    with a password.
- sway2.sh - Install a system. It installs very minimal set of tools, such as,
    alacritty terminal, firefox, openssh and git to make your setup being ready
    for the further configuration.

## Install

- Boot the system from memory via Archlinux USB stick.
- `pacman -Syy`
- `pacman -S git`
- `git clone https://github.com/elijahdanko/distro-init.git`
- `cd distro-init`
- `bash sway1.sh`
-  When sway1.sh installation completed by coping sway2.sh to the mounted
   system, then run `bash sway2.sh`
