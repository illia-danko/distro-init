Automating scripts to setup an operating system

Q: If disaster happened, how fast you can recover the system?<br/>
A: Me: from absolute zero to the complete functional system - 20 minutes (assume
having USB live sticker).

How?

- step1: install operating system from script (all the repo about).
- step2 (optional): download from some very secret place SSH secrets.
- step3: initialize the system via dotfiles script.

## Environments
- lvm-luks.sh - prepare a hard drive. Install linux over lvm + luks hard
  drive encryption.
- sway-env.sh - install sway wm with a default configuration along with alacritty
  and firefox.
- gnome-env.sh - install latest Gnome 3 environment.
- awesome-env.sh - install Awesome WM.

## Install

- Boot the system from memory via Archlinux USB stick.
- `pacman -Syy`
- `pacman -S git`
- `git clone https://github.com/elijahdanko/distro-init.git`
- `cd distro-init; bash lvm-luks.sh`
- When [lvm-luks.sh](/lvm-luks.sh) is finished, run `bash <your_env>.sh` to finish installation.

# License

MIT
