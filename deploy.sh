#!/bin/bash

# Boring stuff you should probably do now
ln -sf /usr/share/zoneinfo/"$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
echo -e "LANG=en_GB.UTF8
LANGUAGE=en_GB.UTF8
LC_COLLATE=C" >/etc/environment
echo -e "FONT_MAP=8859-2
KEYMAP=$MY_KEYMAP" >/etc/vconsole.conf

# Host stuff
echo -e "$MY_HOSTNAME" >/etc/hostname
mkdir -p /etc/conf.d
echo -e "hostname=$MY_HOSTNAME" >/etc/conf.d/hostname
printf "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n" "$MY_HOSTNAME" "$MY_HOSTNAME" >/etc/hosts

# User
useradd -m -G users,audio,video -s /bin/bash $MY_USERNAME
yes "$ROOT_PASSWORD" | passwd $MY_USERNAME

# Root user
yes "$ROOT_PASSWORD" | passwd

# Pacman
sed -i -e 's/Server = http:/#Server = http:/' /etc/pacman.d/mirrorlist
sed -i -e s"/\#VerbosePkgLists/VerbosePkgLists/"g /etc/pacman.conf
sed -i -e s"/\#ParallelDownloads.*/ParallelDownloads = 3/"g /etc/pacman.conf
sed -i -e s"/\#CheckSpace/CheckSpace/"g /etc/pacman.conf
sed -i -e s"/\#CacheDir.*/CacheDir = \/tmp\//"g /etc/pacman.conf
sed -i -e s"/\#NoExtract.*/NoExtract = usr\/share\/doc\/* usr\/share\/gtk-doc\/* usr\/share\/help\/* usr\/share\/info\/* usr\/share\/man\/*/"g /etc/pacman.conf
sed -i -e "s/xz.*/xz -c -z -q - --threads=$(nproc))/;s/^#COMPRESSXZ/COMPRESSXZ/;s/zstd.*/zstd -c -z -q - --threads=$(nproc))/;s/^#COMPRESSZST/COMPRESSZST/;s/lz4.*/lz4 -q --best)/;s/^#COMPRESSLZ4/COMPRESSLZ4/" /etc/makepkg.conf
sed -i -e "s/PKGEXT.*/PKGEXT='.pkg.tar.lz4'/g" /etc/makepkg.conf
sed -i -e "s|OPTIONS=(.*|OPTIONS=(strip !docs !libtool !staticlibs emptydirs zipman purge !debug lto)|g" /etc/makepkg.conf
sed -i -e "s/-j.*/-j$(expr $(nproc) - 1) -l$(nproc)\"/;s/^#MAKEFLAGS/MAKEFLAGS/;s/^#RUSTFLAGS/RUSTFLAGS/" /etc/makepkg.conf

cp -rfd /etc/pacman.conf /etc/pacman.conf.bak

echo -e "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://mirrors.qontinuum.space/artixlinux-universe/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/\$arch
Server = https://artix.sakamoto.pl/universe/\$arch
# TOR
Server = http://rrtovkpcaxl6s2ommj5tigyxamzxaknasd74ecb5t5cdfnkodirjnwyd.onion/artixlinux/\$arch
" >>/etc/pacman.conf

pacman -Sy --noconfirm artix-keyring artix-archlinux-support

echo -e "
# Arch
[extra]
Include = /etc/pacman.d/mirrorlist-arch

#[community]
#Include = /etc/pacman.d/mirrorlist-arch

#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch
" >>/etc/pacman.conf

pacman -Sy && pacman-key --init && pacman-key --populate archlinux
pacman -Sy --noconfirm --disable-download-timeout acpid-$MY_INIT alsa-utils bluez-$MY_INIT doas fwupd gtk-engines gtk-engine-murrine haveged-$MY_INIT jitterentropy libva-mesa-driver macchanger mesa mesa-vdpau openbox pipewire pipewire-alsa pipewire-pulse rsync thermald-$MY_INIT tmux tor-$MY_INIT torsocks unzip vim vulkan-mesa-layers wayland wget wireplumber wpa_supplicant xdg-desktop-portal-gtk xdg-utils xdg-user-dirs xorg xorg-xinit xterm

# Pull my dotfiles
release=$(curl -s https://www.debian.org/releases/stable/ | grep -oP 'Debian [0-9]+' | cut -d " " -f2 | head -n 1)
cd /tmp
wget -qO cbpp-ui-theme.zip https://github.com/CBPP/cbpp-ui-theme/archive/refs/heads/$release.zip && unzip cbpp-ui-theme.zip && mv cbpp-ui-theme-$release cbpp-ui-theme
rm -rfd /usr/share/themes/CBPP*
rm -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/CBPP/xf*
cp -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes
rm -rfd /usr/share/backgrounds
mkdir -p /usr/share/backgrounds
wget -qO config.zip https://github.com/susukin0/.config/archive/refs/heads/artix.zip && unzip config.zip && mv .config-artix .config
rm -rfd /home/$MY_USERNAME/*
rm -rfd /etc/skel/*
rm -rfd /root/*
rm -rfd /home/$MY_USERNAME/.*
rm -rfd /etc/skel/.*
rm -rfd /root/.*
rmdir -p /home/$MY_USERNAME/*
rmdir -p /etc/skel/*
rmdir -p /root/*
mkdir -p /home/$MY_USERNAME/.config
mkdir -p /etc/skel/.config
mkdir -p /root/.config
mkdir -p /home/$MY_USERNAME/.local
mkdir -p /etc/skel/.local
mkdir -p /root/.local
mkdir -p /etc/skel/backup
cp -rfd .config/.gmrunrc /home/$MY_USERNAME
cp -rfd .config/.gtkrc-2.0 /home/$MY_USERNAME/.gtkrc-2.0
cp -rfd .config/.fonts.conf /home/$MY_USERNAME
cp -rfd .config/.gtk-bookmarks /home/$MY_USERNAME
cp -rfd .config/.vimrc /home/$MY_USERNAME
cp -rfd .config/.xinitrc /home/$MY_USERNAME
cp -rfd .config/.Xresources /home/$MY_USERNAME
cp -rfd .config/.nanorc /home/$MY_USERNAME
cp -rfd .config/.mkshrc /home/$MY_USERNAME
cp -rfd .config/.profile /home/$MY_USERNAME
cp -rfd .config/.gmrunrc /etc/skel
cp -rfd .config/.gtkrc-2.0 /etc/skel/.gtkrc-2.0
cp -rfd .config/.fonts.conf /etc/skel
cp -rfd .config/.gtk-bookmarks /etc/skel
cp -rfd .config/.vimrc /etc/skel
cp -rfd .config/.xinitrc /etc/skel
cp -rfd .config/.Xresources /etc/skel
cp -rfd .config/.nanorc /etc/skel
cp -rfd .config/.mkshrc /etc/skel
cp -rfd .config/.profile /etc/skel
mv .config/.gmrunrc /root
mv .config/.gtkrc-2.0 /root/.gtkrc-2.0
mv .config/.fonts.conf /root
mv .config/.gtk-bookmarks /root
mv .config/.vimrc /root
mv .config/.xinitrc /root
mv .config/.Xresources /root
mv .config/.nanorc /root
mv .config/.mkshrc /root
mv .config/.profile /root
mv .config/default-tile.png /usr/share/backgrounds/default-tile.png
rm -rfd /usr/share/icons/CBPP*
cp -rfd .config/CBPP /usr/share/icons
cp -rfd .config/openbox-3 /usr/share/themes/CBPP
mkdir -p /usr/share/icons/default
cp -rfd .config/CBPP/index.theme /usr/share/icons/default
cp -rfd .config/.newsboat /home/$MY_USERNAME/.newsboat
cp -rfd .config/.newsboat /etc/skel/.newsboat
cp -rfd .config/.newsboat /root/.newsboat
cp -rfd .config/.local/* /home/$MY_USERNAME/.local
cp -rfd .config/.local/* /etc/skel/.local
cp -rfd .config/.local/* /root/.local
cp -rfd .config/* /home/$MY_USERNAME/.config
cp -rfd .config/* /etc/skel/.config
cp -rfd .config/* /root/.config
mkdir -p /var/cache/libx11/compose
mkdir -p /home/$MY_USERNAME/.compose-cache
touch /home/$MY_USERNAME/.XCompose
chown -hR $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.*
chown -hR $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/*
find /home/$MY_USERNAME/.config/ | grep '\CBPP' | xargs rm -rfd
find /etc/skel/.config/ | grep '\CBPP' | xargs rm -rfd
find /root/.config/ | grep '\CBPP' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | grep '\themes' | xargs rm -rfd
find /etc/skel/.config/ | grep '\themes' | xargs rm -rfd
find /root/.config/ | grep '\themes' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | grep '\openbox-3' | xargs rm -rfd
find /etc/skel/.config/ | grep '\openbox-3' | xargs rm -rfd
find /root/.config/ | grep '\openbox-3' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | grep '\cbpp' | xargs rm -f
find /root/.config/ | grep '\cbpp' | xargs rm -f

# Other stuff you should do
echo "permit persist :$MY_USERNAME
permit nopass $MY_USERNAME as root cmd macchanger
permit nopass $MY_USERNAME as root cmd openvpn
permit nopass $MY_USERNAME as root cmd pacman
permit nopass $MY_USERNAME as root cmd fwupdmgr
permit nopass $MY_USERNAME as root cmd poweroff
permit nopass $MY_USERNAME as root cmd reboot
permit nopass $MY_USERNAME as root cmd killall
permit nopass $MY_USERNAME as root cmd renice
permit nopass $MY_USERNAME as root cmd sv
permit nopass $MY_USERNAME as root cmd modprobe
permit nopass $MY_USERNAME as root cmd rmmod" >/etc/doas.conf

sed -i -e "s/replaceme/$MY_KEYMAP/" /home/$MY_USERNAME/.config/openbox/autostart
sed -i -e "s/replaceme/$MY_KEYMAP/" /etc/skel/.config/openbox/autostart
sed -i -e "s/replaceme/$MY_KEYMAP/" /root/.config/openbox/autostart

sed -i -e 's/#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/elogind/logind.conf
sed -i -e 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/elogind/logind.conf
sed -i -e 's/#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
sed -i -e 's/#HandlePowerKeyLongPress=.*/HandlePowerKeyLongPress=reboot/' /etc/elogind/logind.conf

echo -e "MALLOC_CONF=background_thread:true
MALLOC_CHECK=0
MALLOC_TRACE=0
MESA_DEBUG=0
LIBGL_DEBUG=0
LIBGL_NO_DRAWARRAYS=1
LIBC_FORCE_NOCHECK=1
HISTCONTROL=ignoreboth:eraseboth
HISTSIZE=0
LESSHISTFILE=-
LESSHISTSIZE=0
LESSSECURE=1
PAGER=less" >>/etc/environment

mkdir -p /etc/modprobe.d
echo -e "blacklist pcspkr
blacklist snd_pcsp
blacklist lpc_ich
blacklist gpio-ich
blacklist iTCO_wdt
blacklist iTCO_vendor_support
blacklist joydev
blacklist mousedev
blacklist mac_hid
blacklist uvcvideo
blacklist parport_pc
blacklist parport
blacklist lp
blacklist ppdev
blacklist sunrpc
blacklist floppy
blacklist arkfb
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist cirrusfb
blacklist cyber2000fb
blacklist kyrofb
blacklist matroxfb_base
blacklist mb862xxfb
blacklist neofb
blacklist pm2fb
blacklist pm3fb
blacklist s3fb
blacklist savagefb
blacklist sisfb
blacklist tdfxfb
blacklist tridentfb
blacklist vt8623fb
blacklist sp5100-tco
blacklist sp5100_tco
blacklist pcmcia
blacklist yenta_socket
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
blacklist n-hdlc
blacklist ax25
blacklist netrom
blacklist x25
blacklist rose
blacklist decnet
blacklist econet
blacklist af_802154
blacklist ipx
blacklist appletalk
blacklist psnap
blacklist p8022
blacklist p8023
blacklist llc
blacklist i2400m
blacklist i2400m_usb
blacklist wimax
blacklist parport
blacklist parport_pc
blacklist cramfs
blacklist freevxfs
blacklist jffs2
blacklist hfs
blacklist hfsplus
blacklist squashfs
blacklist wl
blacklist ssb
blacklist b43
blacklist b43legacy
blacklist bcma
blacklist bcm43xx
blacklist brcm80211
blacklist brcmfmac
blacklist brcmsmac" >/etc/modprobe.d/nomisc.conf

echo -e "options processor ignore_ppc=1" >/etc/modprobe.d/ignore_ppc.conf

echo -e "options drm_kms_helper poll=0" >/etc/modprobe.d/disable-gpu-polling.conf

mkdir -p /etc/modules-load.d
modprobe bfq && echo -e "bfq" >/etc/modules-load.d/bfq.conf
modprobe tcp_bbr && echo -e "tcp_bbr" >/etc/modules-load.d/bbr.conf
modprobe tcp_bbr2 && echo -e "tcp_bbr2" >/etc/modules-load.d/bbr.conf

mkdir -p /lib/sysctl.d
echo -e "net.core.default_qdisc=fq" >/lib/sysctl.d/99-tcp.conf
modprobe tcp_bbr && echo -e "net.ipv4.tcp_congestion_control=bbr" >>/lib/sysctl.d/99-tcp.conf
modprobe tcp_bbr2 && echo -e "net.ipv4.tcp_congestion_control=bbr2" >>/lib/sysctl.d/99-tcp.conf

echo -e "kernel.core_pattern=/dev/null" >/lib/sysctl.d/50-coredump.conf

echo -e "vm.swappiness = 1
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 20
vm.stat_interval = 60
vm.page-cluster = 0
vm.dirty_expire_centisecs = 500
vm.oom_dump_tasks = 1
vm.oom_kill_allocating_task = 1
vm.extfrag_threshold = 750
vm.block_dump = 0
vm.reap_mem_on_sigkill = 1
vm.panic_on_oom = 0
vm.zone_reclaim_mode = 0
vm.scan_unevictable_pages = 0
vm.compact_unevictable_allowed = 1
vm.compaction_proactiveness = 0
vm.page_lock_unfairness = 1
vm.percpu_pagelist_high_fraction = 0
vm.pagecache = 1
vm.watermark_scale_factor = 1
vm.memory_failure_recovery = 0
vm.max_map_count = 262144
min_perf_pct = 100
dev.i915.perf_stream_paranoid = 0
dev.scsi.logging_level = 0
debug.exception-trace = 0
debug.kprobes-optimization = 1
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_queued_events = 1048576
fs.quota.allocated_dquots = 0
fs.quota.cache_hits = 0
fs.quota.drops = 0
fs.quota.free_dquots = 0
fs.quota.lookups = 0
fs.quota.reads = 0
fs.quota.syncs = 0
fs.quota.warnings = 0
fs.quota.writes = 0
fs.leases-enable = 1
fs.lease-break-time = 5
fs.dir-notify-enable = 0
force_latency = 1
net.ipv4.tcp_frto=1
net.ipv4.tcp_frto_response=2
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_ecn=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_early_retrans=2
net.ipv4.tcp_thin_dupack=1
net.ipv4.tcp_autocorking=0
net.ipv4.tcp_reordering=3
net.ipv4.tcp_timestamps=0
net.core.bpf_jit_enable=1
net.core.bpf_jit_harden=0
net.core.bpf_jit_kallsyms=0
vm.mmap_rnd_bits=32
vm.mmap_rnd_compat_bits=16
fs.file-max=1048576
fs.nr_open=1048576
fs.aio-max-nr=524288
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=2
fs.protected_regular=2
fs.suid_dumpable=0" >/lib/sysctl.d/99-swappiness.conf
sysctl -w vm.compact_memory=1 && sysctl -w vm.drop_caches=3 && sysctl -w vm.drop_caches=2

mkdir -p /etc/udev/rules.d
echo -e 'ACTION=="add|change", ATTR{queue/scheduler}=="*bfq*", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/scheduler}="bfq"' >/etc/udev/rules.d/60-scheduler.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/iosched/slice_idle}="0", ATTR{queue/iosched/low_latency}="1"' >/etc/udev/rules.d/90-low-latency.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/add_random}=="0"' >/etc/udev/rules.d/10-add-random.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/iostats}="0"' >/etc/udev/rules.d/20-iostats.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{bdi/read_ahead_kb}="64", ATTR{queue/read_ahead_kb}="64", ATTR{queue/nr_requests}="32"' >/etc/udev/rules.d/70-readahead.rules

sed -i -e 's/^#resolve_names=early/resolve_names=early/' /etc/udev/udev.conf

if $(find /sys/block/nvme[0-9]* | grep -q nvme); then
  echo -e "options nvme_core default_ps_max_latency_us=0" >/etc/modprobe.d/nvme.conf
fi

echo -e "options nf_conntrack nf_conntrack_helper=0" >/etc/modprobe.d/no-conntrack-helper.conf

sed -i -e 's|ext4.*|ext4 rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard 0 1|g' /etc/fstab

echo -e "order bind,hosts
multi on" >/etc/host.conf

echo -e "* soft nofile 1024000
* hard nofile 1024000" >/etc/security/limits.conf

echo -e "session required pam_limits.so" >>/etc/pam.d/common-session
echo -e "session required pam_limits.so" >>/etc/pam.d/common-session-noninteractive

sed -i -e 's|022|077|g' /etc/login.defs

cat /dev/null >/etc/securetty

echo -e "noarp" >>/etc/dhcpcd.conf

echo -e "/home/$MY_USERNAME/.local/bin/mksh" >>/etc/shells

tee /etc/issue <<"EOF"
                   '
                  'o'
                 'ooo'
                'ooxoo'
               'ooxxxoo'
              'oookkxxoo'
             'oiioxkkxxoo'
            ':;:iiiioxxxoo'
               `'.;::ioxxoo'
          '-.      `':;jiooo'
         'oooio-..     `'i:io'
        'ooooxxxxoio:,.   `'-;'
       'ooooxxxxxkkxoooIi:-.  `'
      'ooooxxxxxkkkkxoiiiiiji'
     'ooooxxxxxkxxoiiii:'`     .i'
    'ooooxxxxxoi:::'`       .;ioxo'
   'ooooxooi::'`         .:iiixkxxo'
  'ooooi:'`                `'';ioxxo'
 'i:'`                          '':io'
'`                                   `'

\s \r (\m) (\l) \d \t

EOF

ln -s /etc/runit/sv/acpid/ /etc/runit/runsvdir/current
ln -s /etc/runit/sv/dhcpcd/ /etc/runit/runsvdir/current
ln -s /etc/runit/sv/haveged/ /etc/runit/runsvdir/current
ln -s /etc/runit/sv/thermald/ /etc/runit/runsvdir/current
ln -s /etc/runit/sv/tor/ /etc/runit/runsvdir/current
ln -s /etc/runit/sv/wpa_supplicant/ /etc/runit/runsvdir/current

if [ "$ENCRYPTED" = "y" ]; then
  ln -s /etc/runit/sv/dmcrypt/ /etc/runit/runsvdir/current
fi

# Configure mkinitcpio
if [ "$ENCRYPTED" = "y" ]; then
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect modconf keyboard block encrypt filesystems)/g' /etc/mkinitcpio.conf
else
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect modconf block filesystems)/g' /etc/mkinitcpio.conf
fi

sed -i -e 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
sed -i -e 's/#COMPRESSION_OPTIONS=.*/COMPRESSION_OPTIONS=("--best")/g' /etc/mkinitcpio.conf

mkinitcpio -P

# Install boot loader
if [ "$ENCRYPTED" = "y" ]; then
  sed -i -e "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=$PART2:root root=/dev/mapper/root quiet rootfstype=ext4,btrfs,xfs,f2fs biosdevname=0 nowatchdog noautogroup noresume zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=zsmalloc workqueue.power_efficient=1 pci=pcie_bus_perf,noaer rd.plymouth=0 plymouth.enable=0 plymouth.ignore-serial-consoles logo.nologo consoleblank=0 vt.global_cursor_default=0 rd.systemd.show_status=auto loglevel=0 rd.udev.log_level=0 udev.log_priority=0 audit=0 nosoftlockup selinux=0 enforcing=0 mce=0 mds=full,nosmt vsyscall=none irqpoll threadirqs irqaffinity=0 noirqdebug iomem=relaxed noatime boot_delay=0 io_delay=none rootdelay=0 elevator=noop realloc init_on_alloc=0 init_on_free=0 no_stf_barrier mitigations=off ftrace_enabled=0 fsck.repair=no fsck.mode=skip\"|g" /etc/default/grub
  sed -i -e '/GRUB_ENABLE_CRYPTODISK=y/s/^#//g' /etc/default/grub
else
  sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4,btrfs,xfs,f2fs biosdevname=0 nowatchdog noautogroup noresume zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=zsmalloc workqueue.power_efficient=1 pci=pcie_bus_perf,noaer rd.plymouth=0 plymouth.enable=0 plymouth.ignore-serial-consoles logo.nologo consoleblank=0 vt.global_cursor_default=0 rd.systemd.show_status=auto loglevel=0 rd.udev.log_level=0 udev.log_priority=0 audit=0 nosoftlockup selinux=0 enforcing=0 mce=0 mds=full,nosmt vsyscall=none irqpoll threadirqs irqaffinity=0 noirqdebug iomem=relaxed noatime boot_delay=0 io_delay=none rootdelay=0 elevator=noop realloc init_on_alloc=0 init_on_free=0 no_stf_barrier mitigations=off ftrace_enabled=0 fsck.repair=no fsck.mode=skip"/' /etc/default/grub
fi

sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i -e 's/GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=0/' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck

# Encrypt boot loader
GRUB_PASS=$(echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | grub-mkpasswd-pbkdf2 | grep -oE '[^ ]+$')
echo -e "set superusers=$MY_USERNAME
password_pbkdf2 $MY_USERNAME $GRUB_PASS" >>/etc/grub.d/40_custom
sed -i -e 's/class os/class os --unrestricted/' /etc/grub.d/10_linux
grub-mkconfig -o /boot/grub/grub.cfg
