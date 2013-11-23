#!/bin/sh

usage() {
    echo "
Usage: `basename $1` raw_gpt_file_name
"
}

check_parameter() {
    # check whether provide file name for generated image.
    if [ -z "$1" ]; then 
        usage $0
        echo "please speficy a file name for GPT raw image."
        exit 1
    fi
}

create_gpt_image() {
    echo "@@ Create raw image file ..."
    dd if=/dev/null of=$1 bs=1M seek=4096

    echo "@@ Create GPT parition table ..."
    parted -s $1 mklabel gpt

    # Part1: GPT header will use 1M size, so biosgrub is started at 1M
    echo "@@ Create 1M partition for biosgrub which is required by legacy Boot on a GPT disk."
    parted -s $1 mkpart primary fat32 1M 2M
    
    # Part2: size of ESP = 100M
    echo "@@ Create 100M partition for ESP(EFI System Partition"
    parted -s $1 mkpart primary fat32 2M 102M

    # Part3: Size of Root is 2G
    # seems parted does not support ext4, so specify ext2 here
    echo "@@ Create Rootfs"
    parted -s $1 mkpart primary ext2 102M 2150M

    # Part4: The remaining are for swap 1G
    echo "@@ Create swap"
    parted -s $1 mkpart primary linux-swap 2150M 3150M

    # Size of Recovery Partition = 1G
    # # seems parted does not support ext4, so specify ext2 here
    echo "@@ Create 1G recovery partition"
    parted -s $1 mkpart primary ext2 3150M 100%

    # format partitions
    parted -s $1 mkfs 2 fat32
    parted -s $1 mkfs 3 ext2
    parted -s $1 mkfs 4 linux-swap
    parted -s $1 mkfs 5 ext2

    echo "@@ The partition table is as follows:"
    parted -s $1 print
}

check_parameter $1
create_gpt_image $1
