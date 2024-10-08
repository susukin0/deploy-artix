#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo -e "This script must be run as root. Use 'sudo' or run it as root."
  exit 1
fi

[ ! -d /sys/firmware/efi ] && echo -e "Not booted in UEFI mode." && exit 1

case "$(readlink -f /sbin/init)" in
*"runit"*)
  MY_INIT="runit"
  echo -e "Init system: "$MY_INIT""
  ;;
*)
  echo -e "Init system not supported." && exit 1
  ;;
esac

case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
  UCODE="intel-ucode"
  ;;
*"Amd"*)
  UCODE="amd-ucode"
  ;;
esac

confirm_password() {
  stty -echo
  until [ "$pass1" = "$pass2" ] && [ "$pass2" ]; do
    printf "\n%s\n" "$1" >&2 && read -p $"> " pass1
    printf "\nRe-type %s\n" "$1" >&2 && read -p $"> " pass2
  done
  stty echo
  echo -e "$pass2"
}

# Dependencies
pacman -Sy --noconfirm parted
clear

# Load keymap
echo -e "Load keymap (Default: us)" && read -p $"> " MY_KEYMAP
[ ! "$MY_KEYMAP" ] && MY_KEYMAP="us"
loadkeys $MY_KEYMAP

# Choose disk
while :; do
  clear
  sfdisk -l | grep -E "/dev/"
  echo ""
  echo -e "WARNING: The selected disk will be rewritten."
  echo -e "Disk to install to (e.g. /dev/Xda)" && read -p $"> " MY_DISK
  [ -b "$MY_DISK" ] && break
done

PART1="$MY_DISK"1
PART2="$MY_DISK"2

case "$MY_DISK" in
*"nvme"*)
  PART1="$MY_DISK"p1
  PART2="$MY_DISK"p2
  ;;
esac

ROOT_PART=$PART2

# Encrypt
until [ ! -e $ENCRYPTED ]; do
  clear
  echo -e "Encrypt filesystem? (y/Default: n)" && read -p $"> " ENCRYPTED
  [ ! "$ENCRYPTED" ] && ENCRYPTED="n"
done

# Timezone
until [ -f /usr/share/zoneinfo/"$REGION_CITY" ]; do
  clear
  echo -e "Region/City (Default: Europe/Moscow)" && read -p $"> " REGION_CITY
  [ ! "$REGION_CITY" ] && REGION_CITY="Europe/Moscow"
done

# Host
while :; do
  clear
  echo -e "Hostname (Default: localhost)" && read -p $"> " MY_HOSTNAME
  [ ! "$MY_HOSTNAME" ] && MY_HOSTNAME="localhost"
  [ "$MY_HOSTNAME" ] && break
done

# Username
while :; do
  clear
  echo -e "Username (Default: artix)" && read -p $"> " MY_USERNAME
  [ ! "$MY_USERNAME" ] && MY_USERNAME="artix"
  [ "$MY_USERNAME" ] && break
done

# Root
ROOT_PASSWORD=$(confirm_password "Password for superuser (will use same for root)")

# Network
while :; do
  clear
  echo -e "Wi-Fi SSID (Leave empty for Ethernet)" && read -p $"> " SSID
  [ ! "$SSID" ] && break
  until [ ! -e $PSK ]; do
    echo -e "Wi-Fi Password" && read -p $"> " PSK
  done
  [ "$PSK" ] && break
done

# Partition disk
swapoff -a
umount -AR /mnt*
cryptsetup close /dev/mapper/root

clear
#dd if=/dev/zero of=$MY_DISK bs=2M status=progress && sync || sync
#dd if=/dev/urandom of=$MY_DISK bs=2M status=progress && sync || sync

parted -s "$MY_DISK" mklabel gpt
parted -s "$MY_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$MY_DISK" mkpart primary ext4 512MiB 100%
parted -s "$MY_DISK" set 1 boot on

# Encrypt drive
if [ "$ENCRYPTED" = "y" ]; then
  clear
  cryptsetup -q -y luksFormat --pbkdf=pbkdf2 "$ROOT_PART"
  cryptsetup open "$ROOT_PART" root

  ROOT_PART="/dev/mapper/root"
fi

# Format and mount partitions
mkfs.fat -F 32 "$PART1"
fatlabel "$PART1" ESP
mkfs.ext4 -L root -F -O ^quota,^has_journal,^metadata_csum,uninit_bg -b2048 -m1 "$ROOT_PART"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi
# Create swapfile
SWAP_SIZE=$(echo $(($(free -g | awk '/^Mem:/{print $2}') * 2)))
mkdir /mnt/swap
fallocate -l "$SWAP_SIZE"G /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Install base system and kernel
clear
echo -e 'Done with configuration. Installing...'

if [ "$ENCRYPTED" = "y" ]; then
  basestrap /mnt base $MY_INIT elogind-$MY_INIT efibootmgr dbus-$MY_INIT dhcpcd-$MY_INIT grub $UCODE wpa_supplicant-$MY_INIT cryptsetup-$MY_INIT
else
  basestrap /mnt base $MY_INIT elogind-$MY_INIT efibootmgr dbus-$MY_INIT dhcpcd-$MY_INIT grub $UCODE wpa_supplicant-$MY_INIT
fi

basestrap /mnt linux-zen linux-zen-headers linux-firmware mkinitcpio

fstabgen -U /mnt >/mnt/etc/fstab

# Save connection
if [ "$SSID" ]; then
  echo -e "update_config=1
ap_scan=1
fast_reauth=1
network={
ssid=\"$SSID\"
psk=\"$PSK\"
scan_ssid=1  
}" >/mnt/etc/wpa_supplicant/wpa_supplicant.conf
fi

# Chroot
(MY_INIT="$MY_INIT" PART2="$PART2" ROOT_PASSWORD="$ROOT_PASSWORD" ENCRYPTED="$ENCRYPTED" REGION_CITY="$REGION_CITY" MY_HOSTNAME="$MY_HOSTNAME" MY_USERNAME="$MY_USERNAME" MY_KEYMAP="$MY_KEYMAP" artix-chroot /mnt /bin/bash -c 'bash <(curl -s https://raw.githubusercontent.com/susukin0/deploy-artix/main/deploy.sh); exit')

# Perform finish
swapoff -a
umount -AR /mnt*
cryptsetup close "$ROOT_PART"

clear
echo -e 'Installation completed successfully. You may now reboot or poweroff...'
