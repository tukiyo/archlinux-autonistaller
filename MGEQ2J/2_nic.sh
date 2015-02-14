#!/bin/sh
set -ux
CHROOT="arch-chroot /mnt"

#----------------------
# ネットワーク設定用
#----------------------
BR1='192.168.0.2/24'
# ens9 : 右側Thunderbolt Network, enp0s20u1 : USB-LAN"
BOND1_INTERFACES="ens9 enp0s20u1"

#-----------------------
# chroot->network->bond1
#-----------------------
cat > /mnt/etc/netctl/bond1 <<EOF
Description='Bond1 Interface'
Interface='bond1'
Connection=bond
BindsToInterfaces=($BOND1_INTERFACES)
EOF
$CHROOT netctl enable bond1

#----------------------------
# chroot->network->bond1->br1
#----------------------------
cat > /mnt/etc/netctl/br1 <<EOF
Interface=br1
Connection=bridge
BindsToInterfaces=(bond1)
IP=static
Address=('$BR1')
EOF
$CHROOT netctl enable br1

#-------------------------
# chroot->network->usb-net
#-------------------------
touch /mnt/etc/modules-load.d/usb-net.conf
grep "usbnet" /mnt/etc/modules-load.d/usb-net.conf
if [ $? -eq 1 ];then
    cat >> /mnt/etc/modules-load.d/usb-net.conf <<EOF
usbnet
ax88179_178a
EOF
fi

#------------
# finish
#------------
set +x
echo "---------"
echo "finished."
echo "---------"
