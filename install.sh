#!/bin/bash

set -e

pacmanList=""
yayList=""

if [ ! -f /usr/bin/vmware ]; then
  sudo pacman -S $(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$" | awk '{print $1"-headers"}' ORS=' ') --noconfirm
fi

function installPacman {
  sudo pacman -Syyu
  
  for soft in ${@}; do
    if ! pacman -T $soft &>/dev/null; then
      sudo pacman -S $soft --noconfirm
    fi
  done
}

function installYay () {
  if ! yay -Syyu &>/dev/null; then
    if [ ! -f /usr/bin/git ]; then
      sudo pacman -S --needed git base-devel
    fi
    rm -Rf ./yay-bin/
    git clone https://aur.archlinux.org/yay-bin.git
    cd ./yay-bin/
    makepkg -si
    cd ../
    rm -Rf ./yay-bin/
  fi

  yay -Syyu --noconfirm
  for softyay in ${@}; do
    if ! yay -T $softyay &>/dev/null; then
      yay -S $softyay --noconfirm
    fi
  done
}

installPacman curl \
  wget \
  vim \
  vi \
  alacritty \
  rsync \
  firefox \
  pwgen \
  htop \
  opera \
  chromium \
  vivaldi \
  vivaldi-ffmpeg-codecs \
  discord \
  virtualbox \
  polkit-gnome \
  libreoffice-fresh \
  filezilla \
  nm-connection-editor \
  networkmanager \
  networkmanager-openvpn \
  ntfs-3g \
  gnome-screenshot \
  smplayer \
  pulsemixer \
  gnome-calculator \
  gnome-system-monitor \
  gparted \
  udisks2 \
  remmina \
  freerdp \
  tmux \
  zip \
  unzip \
  mariadb \
  mariadb-clients \
  postfix \
  php \
  php-apcu \
  php-cgi \
  php-dblib \
  php-embed \
  php-enchant \
  php-fpm \
  php-gd \
  php-imap \
  php-intl \
  php-odbc \
  php-pgsql \
  php-phpdbg \
  php-pspell \
  php-snmp \
  php-sodium \
  php-sqlite \
  php-tidy \
  php-xsl \
  php7 \
  php7-apcu \
  php7-cgi \
  php7-dblib \
  php7-embed \
  php7-enchant \
  php7-gd \
  php7-imap \
  php7-intl \
  php7-odbc \
  php7-pgsql \
  php7-phpdbg \
  php7-pspell \
  php7-snmp \
  php7-sodium \
  php7-sqlite \
  php7-tidy \
  php7-xsl \
  php7-geoip \
  php7-grpc \
  php7-igbinary \
  php7-imagick \
  php7-memcache \
  php7-memcached \
  php7-mongodb \
  php7-redis \
  uwsgi-plugin-php7 \
  npm \
  ruby \
  zsh \
  ttf-font-awesome \
  awesome-terminal-fonts \
  powerline \
  powerline-fonts \
  wqy-bitmapfont \
  wqy-microhei \
  wqy-microhei-lite \
  wqy-zenhei \
  ttf-font-awesome \
  ttf-roboto \
  ttf-roboto-mono \
  noto-fonts-cjk \
  adobe-source-han-serif-cn-fonts \
  picom \
  feh \
  rofi \
  lxappearance \
  thunar \
  thunar-volman \
  xfce4-settings \
  neofetch


installYay vscodium-bin \
  sublime-text-4 \
  google-chrome \
  brave-bin \
  skypeforlinux-stable-bin \
  phpstorm \
  phpstorm-jre \
  bitwarden \
  vmware-workstation \
  arc-gtk-theme \
  polybar

username=`ls -l /opt | grep -i "phpstorm" | awk '{print $3, $4}'`
if [ "$username" = "root root" ]; then
  sudo chown -R $USER:$USER /opt/phpstorm
fi

if [ `systemctl is-enabled NetworkManager` = "disabled" ]; then
  sudo systemctl enable --now NetworkManager
fi

if [ `systemctl is-enabled vmware-networks.service` = "disabled" ]; then
  sudo systemctl enable --now vmware-networks.service
  sudo systemctl enable --now vmware-usbarbitrator.service
fi

if [ `systemctl is-enabled mariadb` = "disabled" ]; then
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    sudo systemctl enable --now mariadb
    sudo mysql -uroot -proot -e "create user root@'%' identified by 'root';"
    sudo mysql -uroot -proot -e "grant all privileges on *.* to root@'%';"
    sudo mysql -uroot -proot -e "grant all privileges on *.* to root@'%';"
fi

if [ `systemctl is-enabled postfix` = "disabled" ]; then
  postfix_file=/etc/postfix/main.cf
  sudo chmod o+w $postfix_file
  sudo sed -i 's/#relayhost = \[an\.ip\.add\.ress\]/relayhost = 127\.0\.0\.1:1025/' $postfix_file
  sudo chmod o-w $postfix_file
  sudo systemctl enable --now postfix
fi

#if [ ! -f /usr/bin/php ]; then
if ! grep "xdebug" /usr/bin/php &>/dev/null; then
  for php_ini in `sudo find /etc -type f -name "php.ini"` ; do
    path_file=${php_ini##/etc/}
    path=${path_file%/php.ini}
    sudo chmod o+w $php_ini
    sudo sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/" $php_ini
    sudo sed -i "s/display_errors = Off/display_errors = On/" $php_ini
    sudo sed -i "s/display_startup_errors = Off/display_startup_errors = On/" $php_ini
    sudo sed -i "s/log_errors = On/log_errors = Off/" $php_ini
    sudo sed -i "s/post_max_size = 8M/post_max_size = 8G/" $php_ini
    sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 8G/" $php_ini
    sudo sed -i "s/;extension=/extension=/" $php_ini
    sudo sed -i "s/;zend_extension=/zend_extension=/" $php_ini

    git clone https://github.com/xdebug/xdebug.git
    cd xdebug
    if [ $path = "php7" ]; then
      php_version=7
    else
      unset php_version
    fi
    
    phpize${php_version}
    ./configure --enable--xdebug
    make
    sudo cp ./modules/xdebug.so /usr/lib64/php${php_version}/modules/
    cd ..
    sudo rm -Rf ./xdebug/
  
    if ! grep "\[xdebug\]" $php_ini &>/dev/null; then
      sudo echo -e "[xdebug]\nzend_extension=/usr/lib64/php${php_version}/modules/xdebug.so" >> $php_ini
    fi
    sudo chmod o-w $php_ini
  done
fi

if [ ! -f /usr/bin/browser-sync ]; then
  sudo npm i -g browser-sync
fi

if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
    exit
EOF
  chsh -s $(which zsh)
  sudo pacman -S --noconfirm keychain
  mkdir -p -m 700 ~/.ssh
  git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
  sed -i "s/ZSH_THEME=\"robbyrussell\"/#ZSH_THEME=\"robbyrussell\"/" ~/.zshrc
  cat >> ~/.zshrc <<EOF
fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure
zmodload zsh/nearcolor
zstyle :prompt:pure:path color '#FFFFFF'
zstyle ':prompt:pure:prompt:*' color cyan
zstyle :prompt:pure:git:stash show yes
eval \$(keychain --eval --agents ssh --quick --quiet)
export TERM=xterm-256color
EOF
fi

if [ ! -d ~/Documents ]; then
  mkdir -p ~/Downloads
  mkdir -p ~/Pictures
  mkdir -p ~/Documents
  mkdir -p ~/Documents/Lab
  mkdir -p ~/Movies
fi

if [ `timedatectl | grep -i "NTP service" | awk '{print $3}'` = "inactive" ]; then
  sudo timedatectl set-timezone Canada/Eastern
  sudo timedatectl set-ntp true
fi

vim_file=/etc/vimrc
if ! grep "set rnu" $vim_file &>/dev/null; then
  sudo chmod o+w $vim_file
  sudo echo -e "\ncolor delek\nset rnu\n" >> $vim_file
  sudo chmod o-w $vim_file
fi

keyboardFile="/etc/X11/xorg.conf.d/00-keyboard.conf"
if ! grep "ca(fr)" $keyboardFile &>/dev/null;then
sudo chown $USER:$USER $keyboardFile
cat <<EOF > $keyboardFile
Section "InputClass"
  Identifier "system-keyboard"
  MatchIsKeyboard "on"
  Option "XkbLayout" "ca(fr)"
  Option "XkbModel" "pc105+inet"
  Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
EOF
  sudo chown root:root $keyboardFile
fi

touchpadFile="/etc/X11/xorg.conf.d/90-touchpad.conf"
if [ ! -f $touchpadFile ]; then
  sudo touch $touchpadFile
  sudo chown $USER:$USER  $touchpadFile
  cat <<EOF > $touchpadFile
Section "InputClass"
  Identifier "touchpad"
  MatchIsTouchpad "on"
  Driver "libinput"
  Option "Tapping" "on"
  Option "TappingButtonMap" "lrm"
  Option "NaturalScrolling" "on"
  Option "ScrollMethod" "twofinger"
EndSection
EOF
  sudo chown root:root $touchpadFile
fi

if [ ! -f /usr/bin/docker ]; then
  sudo pacman -S docker --noconfirm
  if [ `systemctl is-enabled docker.service` = "disabled" ] ; then
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
  fi
  if ! sudo docker ps | grep mail; then
    sudo docker run -d --restart unless-stopped -p 1080:1080 -p 1025:1025 dominikserafin/maildev:latest
  fi
fi

if [ ! -f /swapfile ]; then
  sudo truncate -s 0 /swapfile
  sudo chattr +C /swapfile
  sudo btrfs property set /swapfile compression none

  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  sudo chmod o+w /etc/fstab
  sudo echo "/swapfile none swap defaults 0 0" >> /etc/fstab
  sudo chmod o-w /etc/fstab
fi

grub_file="/etc/default/grub"
if ! grep -i 'GRUB_CMDLINE_LINUX_DEFAULT="quiet acpi_backlight=vendor' ${grub_file} &>/dev/null; then
  sudo chown $USER:$USER $grub_file
  sudo echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet acpi_backlight=vendor"' >> $grub_file
  sudo chown root:root $grub_file
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

rsync -av --chown=$USER:$USER ./profile/ ~/

echo ""
echo "Redémarrer l'ordinateur pour terminer la configuration !"  
exit 0

