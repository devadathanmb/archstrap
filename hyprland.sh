#! /usr/bin/env bash

# Hyprland setup for fresh arch installation

# Hyprland specific setup
hyprland_bootstrap(){
  git clone https://github.com/devadathanmb/dotfiles $HOME/dotfiles
  exec ~/dotfiles/bootstrap.sh
}

hyprland_config(){
  sudo cp /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland-wrapped.desktop 
  cat > /etc/udev/rules.d/backlight.rules << EOL
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
EOL
  
  cat > ~/.config/electron-flags.conf << EOL
--enable-features=UseOzonePlatform --ozone-platform=wayland
EOL
}

# Setup zram
setup_zram(){
  pacman -S --noconfirm zramd
  systemctl enable --now zramd
}

main(){
    hyprland_bootstrap
    hyprland_config
    setup_zram
}
main
