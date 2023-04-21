# Archstrap

This is a basic bootstrap script for my preferred arch linux installation with hyprland wayland compositor.

## What does this script do?

Basically all the good old manual stuff

- Configure pacman and set up mirrors
- Delete all existing partitions
- Create an EFI partition of 500MB and root partition of rest of the space
- Format root partition with btrfs filesystem
- Perform basic pacstrap and install required tools
- Set locale, timezone, localhost, hostname, user, password 
- Set daemon processes 
- Configure grub 
- Bootstrap basic hyprland setup

**Note that this script is made for my requirements, please make necessary changes in the script before you run this**
