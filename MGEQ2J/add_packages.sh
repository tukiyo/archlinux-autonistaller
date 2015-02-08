#!/bin/sh

set -x
CHROOT="arch-chroot /mnt"
PACMAN="$CHROOT pacman -S --noconfirm"
YAOURT="$CHROOT yaourt -S --noconfirm"

#---------
# packages
#---------
$PACMAN \
  net-tools wget screen \
  zsh git tig ranger ack w3m \
$YAOURT nkf fcron

$PACMAN \
  docker lxc pipework-git

#------------
# ntp
#------------
$PACMAN ntpd
$CHROOT sed 's/^server/#server/g' /mnt/etc/ntp.conf
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
# clear cache
#------------
$CHROOT pacman -Sc --noconfirm
