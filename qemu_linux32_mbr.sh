#!/bin/bash

top="$(pwd)"
bios_file=$top/ovmf/ken-IA32/bios.bin
disk_file=$top/images/ubuntu32_mbr.raw
compressed_disk_file=$disk_file.xz
options="-hda $disk_file -m 1024 -serial pty -vga cirrus"
qemu_cmd=qemu-system-i386
addtional=$2

usage() {
    echo "
Usage: `basename $1` [efi|legacy] <addtional options for qemu>
"
}

check_parameter() {
    # check whether specify the efi or legacy boot
    if [ -z "$1" ]; then
        usage $0
        echo "please specify efi or legacy"
        exit 1
    fi
}

check_image_file() {
    if [ ! -f $disk_file ];
    then
        if [ -f $compressed_disk_file ];
        then
            echo "Extract $compressed_disk_file....Zzz"
            cd $top/images
            tar xJf $compressed_disk_file
            cd $top
        else
            echo "Can not find disk image file $disk_file or $compressed_dist_file"
            exit 1
        fi
    fi
}

check_parameter $1
check_image_file

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
