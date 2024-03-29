#! /usr/bin/env bash

# Stop executing if any error occurs
set -e

# Drive to install to 
DRIVE="nvme0n1"

# Hostname
HOSTNAME="arch"

# Username
USERNAME="devadathan"

# Password
PASSWORD="acomplexpassword"

# Timezone
TIMEZONE="Asia/Kolkata"

# Keymap
KEYMAP="us"

# Partition type
PARTITION_TYPE="btrfs"

# Video driver
VIDEO_DRIVER="amd"


# Pre install stuff
pre_install(){
  pacman -S --noconfirm archlinux-keyring
  pacman -Syy
  setfont ter-132n
  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  pacman -S --noconfirm reflector
  reflector -c India --verbose --sort rate -l 10 --save /etc/pacman.d/mirrorlist
}

# Remove all exsiting partitions
remove_partitions(){
  sfdisk --delete /dev/$DRIVE
}

# Partiton drives
partition_drives(){
  gdisk "/dev/$DRIVE" <<EOF
o
y
n
1

+500M
ef00
n
2


8300
w
y
EOF
}

# Format drives
format_drives(){
  mkfs.fat -F32 /dev/$DRIVE"1"
  mkfs.btrfs /dev/$DRIVE"2" -f
}

# Mount drives
mount_drives(){
  local boot_partiton="$DRIVE"1
  local root_partition="$DRIVE"2
  mount /dev/"$root_partition" /mnt

  btrfs su cr /mnt/@
  btrfs su cr /mnt/@home
  btrfs su cr /mnt/@var
  btrfs su cr /mnt/@.snapshots

  umount /mnt

  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/"$root_partition" /mnt
  mkdir -p /mnt/{boot,home,.snapshots,var}
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/"$root_partition" /mnt/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@.snapshots /dev/"$root_partition" /mnt/.snapshots
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@var /dev/"$root_partition" /mnt/var

  mount /dev/"$boot_partiton" /mnt/boot
}

# Base install
install_base(){
  pacstrap -K /mnt base base-devel vim btrfs-progs linux linux-firmware amd-ucode
}

# Chroot into installation
arch_chroot(){
  cp ./install.sh /mnt/root/install.sh
  cp ./hyprland.sh /mnt/root/hyprland.sh
  chown root:root /mnt/root/install.sh
  chown root:root /mnt/root/hyprland.sh
  chmod +x /mnt/root/install.sh
  chmod +x /mnt/root/hyprland.sh
  arch-chroot /mnt /bin/bash << EOF
./root/install.sh chroot
EOF
}

# Set timezone
set_timezone(){
 ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
}

# Set locale
set_locale(){
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  locale-gen
}

# Set hosts
set_hosts(){
  cat >> /etc/hosts << EOF
127.0.0.1           localhost
::1                 localhost
127.0.0.1   	    $HOSTNAME.localdomain	$HOSTNAME
EOF
}

# Generate fstab
gen_fstab(){
  genfstab -U /mnt >> /mnt/etc/fstab
  cat /mnt/etc/fstab
}

# Set hostname
set_hostname(){
  echo "$HOSTNAME" >> /etc/hostname
}

# Install packages
install_packages(){
  pacman -S --noconfirm networkmanager \
  grub \
  efibootmgr \
  network-manager-applet \
  dialog wpa_supplicant \
  mtools \
  dosfstools \
  bluez \
  bluez-utils \
  cups \
  xdg-utils \
  xdg-user-dirs \
  base-devel \
  linux-headers \
  git 
}

# Configure mkinitpio.conf
config_mkinitcpio(){
  sed -i 's/^MODULES=(/MODULES=(btrfs /' /etc/mkinitcpio.conf
  mkinitcpio -p linux
}

# Configure grub
configure_grub(){
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/gurb.cfg
}

# Add users
setup_user(){
  useradd -mG  wheel,video,network,lp,power "$USERNAME"
  echo -en "$PASSWORD\n$PASSWORD" | passwd "$USERNAME"
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/ %wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

# Setup daemons
set_daemons(){
  systemctl enable NetworkManager
  systemctl enable bluetooth
  systemctl enable cups
}

# Configure pacman after chrooting
configure_pacman(){
  pacman -S --noconfirm terminus-font
  setfont ter-132n
  echo "FONT=ter-132n" >> /etc/vconsole.conf
  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  pacman -S --noconfirm reflector
  reflector -c India --verbose --sort rate -l 10 --save /etc/pacman.d/mirrorlist
}

# Before chroot
before_chroot(){
  pre_install
  remove_partitions
  partition_drives
  format_drives
  mount_drives
  install_base
  gen_fstab
  arch_chroot
}

# After chroot
after_chroot(){
  configure_pacman
  set_timezone
  set_locale
  set_hostname
  set_hosts
  install_packages
  config_mkinitcpio
  configure_grub 
  setup_user
  set_daemons
}

if [ "$1" == "chroot" ]
then
  after_chroot
  clear
  cp /root/hyprland.sh /home/$USERNAME
  chown $USERNAME /home/$USERNAME/hyprland.sh
  rm /root/install.sh
  rm /root/hyprland.sh
  echo "Basic arch install complete."
  echo "Now reboot and run your configuration script."

else
  before_chroot
fi
