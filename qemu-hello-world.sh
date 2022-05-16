#!/bin/bash

# Script debug options
#set -x
#set -e

# This script depends on these packages:
sudo apt-get install -y mount extlinux parted util-linux coreutils

SCRIPTDIR=$(pwd)

# Get the image that we're going to alter
if [ ! -f Core-current.iso ] ; then
	wget http://www.tinycorelinux.net/13.x/x86/release/Core-current.iso
fi

# Create 64MB qemu image file
qemu-img create -f raw tc-orig.raw 64M

# Install the boot record
dd if=/usr/lib/syslinux/mbr/mbr.bin of=tc-orig.raw conv=notrunc bs=440 count=1
parted -s tc-orig.raw mklabel msdos
parted -s -a none tc-orig.raw mkpart primary ext4 0 64M
parted -s -a none tc-orig.raw set 1 boot on

# Set up the loopback device
lodevo=$(losetup -f)
sudo losetup ${lodevo} tc-orig.raw
sudo partx -a ${lodevo}

# Create a filesystem
sudo mkfs.ext4 ${lodevo}p1

# Set up mountpoints
mkdir ${SCRIPTDIR}/tciso
mkdir ${SCRIPTDIR}/tc-orig
mkdir ${SCRIPTDIR}/tc-new

# Mount everything up
sudo mount -o loop Core-current.iso ${SCRIPTDIR}/tciso
sudo mount ${lodevo}p1 ${SCRIPTDIR}/tc-orig

# Set up extlinux for booting
sudo mkdir -p ${SCRIPTDIR}/tc-orig/boot/extlinux
echo 'DEFAULT TCL
LABEL TCL
KERNEL /boot/vmlinuz
APPEND initrd=/boot/core.gz quiet norestore' | sudo tee ${SCRIPTDIR}/tc-orig/boot/extlinux/extlinux.conf > /dev/null
sudo cp /usr/lib/syslinux/modules/bios/* /usr/lib/syslinux/memdisk ${SCRIPTDIR}/tc-orig/boot/extlinux
sudo cp ${SCRIPTDIR}/tciso/boot/core.gz ${SCRIPTDIR}/tciso/boot/vmlinuz ${SCRIPTDIR}/tc-orig/boot
sudo extlinux --install ${SCRIPTDIR}/tc-orig/boot/extlinux

# Get a copy of the root image for alteration
cp ${SCRIPTDIR}/tciso/boot/core.gz .

# Unmount everything and clean up.
sudo umount ${SCRIPTDIR}/tciso
sudo umount ${SCRIPTDIR}/tc-orig
rmdir ${SCRIPTDIR}/tciso ${SCRIPTDIR}/tc-orig
sudo losetup -d ${lodevo}

# Expand the root image
mkdir core-scratch
cd core-scratch
zcat ../core.gz | sudo cpio -idv

# Add my new hello worldly additions
echo /etc/init.d/hello-world.sh | sudo tee -a opt/bootsync.sh
sudo install -m 0755 ${SCRIPTDIR}/hello-world.sh ./etc/init.d/hello-world.sh

# Back up the new root image
rm -f ${SCRIPTDIR}/core.gz
sudo find . | sudo cpio -o -H newc | gzip -9 > ${SCRIPTDIR}/core.gz

# Duplicate the base image
cd ${SCRIPTDIR}
cp tc-orig.raw tc-new.raw

# Mount the new image and install the new root image
lodevn=$(losetup -f)
sudo losetup ${lodevn} ${SCRIPTDIR}/tc-new.raw
sudo partx -a ${lodevn}
sudo mount ${lodevn}p1 ${SCRIPTDIR}/tc-new
sudo cp ${SCRIPTDIR}/core.gz ${SCRIPTDIR}/tc-new/boot
sudo umount ${SCRIPTDIR}/tc-new
sudo losetup -d ${lodevn}
rmdir ${SCRIPTDIR}/tc-new

