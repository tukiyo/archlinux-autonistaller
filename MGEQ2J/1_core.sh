#!/bin/sh
set -ux

#----------------------
# ネットワーク設定用
#----------------------
BR0='192.168.100.2/24'
GATEWAY='192.168.100.1'
DNS1='8.8.8.8'
DNS2='8.8.4.4'
# enp3s0f0 : 内蔵NIC, enp0s20u1 : USB-NIC"
BOND0_INTERFACES="enp3s0f0  enp0s20u1"
NEW_HOSTNAME="macmini01.local"

#----------------------
# partitioning /dev/sda
# * sda1 : EFI Filesystem : 100MB
# * sda2 : SWAP : 4GB
# * sda3 : xfs : 残り
#----------------------
gdisk /dev/sda <<EOF
o
y
n
1

+100M
EF00
n
2

+4G
8200
n
3




w
y
EOF


#----------------------
# partitioning /dev/sdb
# * sdb1 : xfs : /
#----------------------
gdisk /dev/sdb <<EOF
o
y
n
1



w
y
EOF

#-------------
# format
#-------------
mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
mkfs.xfs -f /dev/sda3
mkfs.xfs -f /dev/sdb1

#-------------
# mount
#-------------
mount /dev/sdb1 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

#-------------
# mirror
#-------------
cat > /etc/pacman.d/mirrorlist <<EOF
Server = http://ftp.tsukuba.wide.ad.jp/Linux/archlinux/\$repo/os/\$arch
EOF

#-------------
# pacstrap
#-------------
pacstrap /mnt \
  base base-devel vim openssh grub efibootmgr os-prober

#-------------
# genfstab
#-------------
genfstab -U -p /mnt >> /mnt/etc/fstab

#-------------
# chroot
#-------------
CHROOT="arch-chroot /mnt"

#---------------
# chroot->locale
#---------------
$CHROOT sed -i -e 's/#ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen
$CHROOT sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
echo LANG=ja_JP.UTF-8 > /mnt/etc/locale.conf
$CHROOT locale-gen
echo KEYMAP=jp106 > /mnt/etc/vconsole.conf

#-----------------
# chroot->timezone
#-----------------
$CHROOT ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
$CHROOT hwclock --systohc --utc

#-------------------
# chroot->bootloader
#-------------------
$CHROOT mkinitcpio -p linux
$CHROOT grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
$CHROOT sed -i -e 's/^GRUB_TIMEOUT=5$/GRUB_TIMEOUT=1/' /etc/default/grub
$CHROOT grub-mkconfig -o /boot/grub/grub.cfg

#-------------
# chroot->network
#-------------
$CHROOT pacman -S --noconfirm netctl ifenslave
echo "net.ipv4.ip_forward=1" > /mnt/etc/sysctl.d/99-sysctl.conf

#-----------------------
# chroot->network->bond0
#-----------------------
cat > /mnt/etc/netctl/bond0 <<EOF
Description='Bond0 Interface'
Interface='bond0'
Connection=bond
BindsToInterfaces=($BOND0_INTERFACES)
EOF
cat > /mnt/etc/modprobe.d/bonding.conf <<EOF
options bonding miimon=100
options bonding mode=active-backup
EOF
$CHROOT netctl enable bond0

#----------------------------
# chroot->network->bond0->br0
#----------------------------
cat > /mnt/etc/netctl/br0 <<EOF
Interface=br0
Connection=bridge
BindsToInterfaces=(bond0)
IP=static
Address=('$BR0')
Gateway='$GATEWAY'
DNS=('$DNS1' '$DNS2')
EOF
$CHROOT netctl enable br0

#-------------
# yaourt
#-------------
grep "archlinuxfr" /mnt/etc/pacman.conf
if [ $? -eq 1 ];then
    cat >> /mnt/etc/pacman.conf <<EOF
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
EOF
fi
$CHROOT pacman -Sy --noconfirm archlinuxfr/yaourt

#-------------
# finish
#-------------
$CHROOT pacman -Syu --noconfirm
$CHROOT pacman -Sc --noconfirm
$CHROOT echo "$NEW_HOSTNAME" > /mnt/etc/hostname
$CHROOT systemctl enable sshd
$CHROOT passwd
set +x
echo "-----------------"
echo "install finished."
echo "-----------------"
