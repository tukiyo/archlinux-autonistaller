#!/bin/sh
set -ux
CHROOT="arch-chroot /mnt"
PACMAN="$CHROOT pacman -S --noconfirm"
YAOURT="$CHROOT sudo -u vagrant yaourt -S --noconfirm"

#------------
# kvm
#------------
$PACMAN qemu libvirt dmidecode ebtables
$CHROOT systemctl enable libvirtd

touch /mnt/etc/modprobe.d/kvm-nested.conf
grep "kvm_intel" /mnt/etc/modprobe.d/kvm-nested.conf
if [ $? != 0 ];then
  cat >> /mnt/etc/modprobe.d/kvm-nested.conf <<EOF
options kvm_intel nested=1
EOF
fi

touch /mnt/etc/modules-load.d/virtio-net.conf
grep "virtio-net" /mnt/etc/modules-load.d/virtio-net.conf
if [ $? != 0 ];then
  cat >> /mnt/etc/modules-load.d/virtio-net.conf <<EOF
virtio-net
EOF
fi

sed -i -e 's/^#user = "root"/user = "root"/' /mnt/etc/libvirt/qemu.conf

#------------
# kvm->vnc
#------------
VNCPASS="VncP@ss"
$PACMAN xorg-mkfontscale xorg-mkfontdir ttf-sazanami
$PACMAN tigervnc blackbox xorg-setxkbmap xterm
mkdir /mnt/root/.vnc/
echo "setxkbmap -model jp106 -layout jp" >> /mnt/root/.vnc/xstartup
echo "blackbox &" >> /mnt/root/.vnc/xstartup
echo "virt-manager &" >> /mnt/root/.vnc/xstartup
echo $VNCPASS | $CHROOT vncpasswd -f > /mnt/root/.vnc/passwd
chmod 600 /mnt/root/.vnc/passwd

#------------
# finish
#------------
set +x
echo "---------"
echo "finished."
echo "---------"
