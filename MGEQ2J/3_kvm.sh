#!/bin/sh
set -ux
CHROOT="arch-chroot /mnt"
PACMAN="$CHROOT pacman -S --noconfirm"
YAOURT="$CHROOT sudo -u vagrant yaourt -S --noconfirm"

#------------
# kvm
#------------
$PACMAN qemu libvirt dmidecode ebtables openbsd-netcat

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

$CHROOT systemctl enable libvirtd

#-------------
# virt-manager
#-------------
#$CHROOT systemctl enable docker
#$CHROOT systemctl start docker
#$CHROOT docker pull tukiyo3/virt-manager
echo "docker run -it -d -p 5900:5900 tukiyo3/virt-manager" > /mnt/root/virt-manager.sh
chmod +x /mnt/root/virt-manager.sh

#------------
# finish
#------------
set +x
echo "---------"
echo "finished."
echo "---------"
