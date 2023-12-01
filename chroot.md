##Chroot
---

#v1
sudo mount -t proc proc /proc
sudo mount -t sysfs sys /sys
sudo mount -t devtmpfs dev /dev
sudo mount -t devpts devpts /dev/pts

#v2
cd /path/to/new/root
mount -t proc /proc proc/
mount -t sysfs /sys sys/
mount --rbind /dev dev/
mount --rbind /run run/
mount --rbind /sys/firmware/efi/efivars sys/firmware/efi/efivars/
