#! /usr/bin/env bash

#Script to modestly harden a new installation of Mint (aimed at Mint 19).
#...and to add some frequently used and recommended apps
#Threat model is a desktop box protected against an opportunistic attacker...
#...e.g. cyber-criminal that is looking for low hanging fruit.

#Bomb out if not sudo'd or run as root
if [[ $EUID -ne 0 ]]; then
   	echo "$(tput setaf 2)You'll need to run this as root"
   	exit 1
else

  echo ''
  echo '#------------------------------------#'
  echo '#     Mint Post-Install Script       #'
  echo '#         Secure Active CIC          #'
  echo '#------------------------------------#'
  echo ''

  #Update repos and upgrade without prompting
  echo "$(tput setaf 2)Updating and Upgrading"
  apt-get update && sudo apt-get upgrade -y

  #Install some bits and bobs
  apt-get install -y wget curl apt-transport-https

  #Turn the firewall on and set the 'public' profile
  apt-get install ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw enable
  #Ask if SSH needs to be enabled
  echo -n "$(tput setaf 2)Do you need to use SSH on this box (y/n)? "
  read -r answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    ufw deny ssh
    echo "$(tput setaf 2)SSH has been disallowed"
  else
    ufw allow ssh
    echo "$(tput setaf 2)SSH has been allowed"
  fi

  #Set root password - HASHED OUT FOR TESTING
  #echo "Set a password for root"
  #passwd root

  #Install AppArmor (we need a level of Mandatory Access Control)
  apt-get install -y apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra
  aa-enforce /etc/apparmor.d/*
  systemctl enable apparmor
  systemctl restart apparmor

  #Install KeepassXC
  echo "$(tput setaf 2)Installing KeepassXC"
  apt-get install keepassxc

  #Install Wire
  echo "$(tput setaf 2)Installaing Wire"
  wget -q https://wire-app.wire.com/linux/releases.key -O- | sudo apt-key add -
  echo "deb https://wire-app.wire.com/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/wire-desktop.list
  apt-get update
  apt-get install wire-desktop

  #Install Signal
  curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
  echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list
  sudo apt update && sudo apt install signal-desktop

  #Install Veracrypt
  echo "$(tput setaf 2)Installing Veracrypt..."
  add-apt-repository ppa:unit193/encryption -y
	apt-get update
	apt-get install veracrypt -y

  #Install Tresorit
  echo "$(tput setaf 2)Installing Tresorit..."
  cd ~
  mkdir Tresorit
  cd Tresorit
  wget https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run
  sh ./tresorit_installer.run

  #Install Tor Browser
  echo "$(tput setaf 2)Installing Tor Browser..."
  apt-get install torbrowser-launcher

  #Install ProtonVPN
  echo -n "$(tput setaf 2)Do you want to install ProtonVPN (y/n)? "
  read -r answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "$(tput setaf 2)Installing ProtonVPN..."
    apt-get install -y openvpn python dialog sysctl sha512sum git
    git clone "https://github.com/protonvpn/protonvpn-cli"
    cd protonvpn-cli
    ./protonvpn-cli.sh --install
  else
    echo "$(tput setaf 2)No ProtonVPN for you..."
  fi

  #Install the anti-virus ClamTK
  echo "$(tput setaf 2)Installing ClamTK..."
  apt-get install -y clamtk
  mkdir ~/virus
  echo "$(tput setaf 2)Scanning for malware, probably best to get a coffee..."
  clamscan -r -i --move=$HOME/virus .
  systemctl stop clamav-freshclam
  sudo freshclam
  sudo systemctl start clamav-freshclam

  #Install RKHunter - a rootkit hunter
  echo "$(tput setaf 2)Installing RKHunter..."
  apt-get install -y rkhunter && rkhunter --update && rkhunter --propupd
  #Add rkhunter to cron to run weekly

  #Remove Mono & Orca
  echo "$(tput setaf 2)Removing Mono & Orca..."
  apt-get remove -y mono-runtime-common gnome-orca -y

  #Install Lynis - Security auditor
  echo "$(tput setaf 2)Installing Lynis - Security Auditor..."
  sudo wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -
  apt install apt-transport-https
  echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
  echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
  apt update
  apt-get install lynis
  echo "$(tput setaf 2)To run Lynis enter 'lynis audit system'"

  #Sign off
  echo ''
  echo '#------------------------------------#'
  echo '#          Script Finished           #'
  echo '#         Secure Active CIC          #'
  echo '# More config is required see GitHub #'
  echo '#------------------------------------#'
  echo ''

fi
