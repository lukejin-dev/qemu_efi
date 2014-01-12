#!/bin/bash

disk_file=$2
addtional=$3

top="$(pwd)"
bios_file=$top/ovmf/ken-X64/bios.bin
compressed_disk_file=$disk_file.xz
options="-hda $disk_file -m 1024 -serial pty"
qemu_cmd=qemu-system-x86_64

usage() {
    echo "
Usage: `basename $1` [efi|legacy] <disk_image_file> <addtional options for qemu>
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
        echo "please specify the disk image file as second parameter"
        exit 1
    fi
}

check_parameter $1 $2

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
