#!/bin/bash

disk_file=$2
addtional=$3

top="$(pwd)"
bios_file=$top/ovmf/ken-IA32/bios.bin
options="-hda $disk_file -m 1024 -serial pty -vga cirrus"
qemu_cmd=qemu-system-i386

usage() {
    echo "
Usage: `basename $1` [efi|legacy] <disk_image> <addtional options for qemu>
"
}

check_parameter() {
    # check whether specify the efi or legacy boot
    if [ -z "$1" ]; then
        usage $0
        echo "please specify efi or legacy"
        exit 1
    fi

    if [ -z "$2" ]; then
        usage $0
        echo "please specify disk image file"
        exit 1
    fi
}

check_parameter $1

case $1 in
    efi)
        bios_flag="-bios $bios_file"
        ;;
    legacy)
        bios_flag=" "
        ;;
    *)
        usage $0
        echo "please specify efi or legacy"
        exit 1
esac

echo "@@ Start qemu ...."
$qemu_cmd $options $bios_flag $addtional &
echo "Please notice the number of pts device like /dev/pts/3, then use \"screen /dev/pts/3\" to start serial console"
