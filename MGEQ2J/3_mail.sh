#!/bin/sh
set -ux
CHROOT="arch-chroot /mnt"
PACMAN="$CHROOT pacman -S --noconfirm"
YAOURT="$CHROOT sudo -u vagrant yaourt -S --noconfirm"

#------------
# mail
#------------
$PACMAN postfix procmail
$YAOURT mutt

#------------
# logwatch
#------------
$PACMAN logwatch pflogsumm

#------------
# finish
#------------
set +x
echo "---------"
echo "finished."
echo "---------"
