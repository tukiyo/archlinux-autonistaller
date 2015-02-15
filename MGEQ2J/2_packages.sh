#!/bin/sh
set -ux
CHROOT="arch-chroot /mnt"
PACMAN="$CHROOT pacman -S --noconfirm"
YAOURT="$CHROOT sudo -u vagrant yaourt -S --noconfirm"

#-----------------------------------------------------------------------
# yaourt用にvagrantユーザを作成する。パスワードはvagrant。後で消すこと!!
#-----------------------------------------------------------------------
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/vagrant
PASS=$(perl -e 'print crypt("vagrant", "salt"),"\n"')
$CHROOT useradd -m -G wheel -p ${PASS} vagrant

#---------
# packages
#---------
$PACMAN \
  net-tools wget screen \
  zsh git tig ranger ack w3m
$YAOURT nkf

#----------
# etckeeper
#----------
$YAOURT aur/etckeeper
$CHROOT etckeeper init
$CHROOT etckeeper commit init

#------------
# container
#------------
$PACMAN docker lxc dnsmasq protobuf-c
$YAOURT yum

#------------
# fcron
#------------
$YAOURT fcron
$CHROOT systemctl enable fcron

#------------
# ntp
#------------
$PACMAN ntp
$CHROOT sed -i -e 's/^server/#server/g' /mnt/etc/ntp.conf
grep "mfeed" /mnt/etc/ntp.conf
if [ $? != 0 ];then
  cat >> /mnt/etc/ntp.conf <<EOF
server -4 ntp.nict.jp
server -4 ntp1.jst.mfeed.ad.jp
server -4 ntp2.jst.mfeed.ad.jp
server -4 ntp3.jst.mfeed.ad.jp
EOF
fi
$CHROOT systemctl enable ntpd

#------------
# others
#------------
$PACMAN lm_sensors

#------------
# clear cache
#------------
$CHROOT pacman -Sc --noconfirm

#------------
# finish
#------------
set +x
echo "---------"
echo "finished."
echo "---------"
