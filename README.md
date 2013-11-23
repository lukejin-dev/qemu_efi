qemu_efi
========
This package provide:

1, Tools to create raw GPT image
2, Pre-build OVMF 32/64-bit UEFI BIOS binary with debug build and serial output
3, The image for ubuntu server 32bit which can be boot with 2) OVMF UEFI BIOS IA32 binary in qemu.
4, The image for ubuntu server 32bit which can be boot with 2) OVMF UEFI BIOS X64 binary in qemu. 

You can use the RAW image in above 3 & 4 to create USB boot disk to boot with UEFI 32-bit BIOS or UEFI 64-bit BIOS.

Please reference https://docs.google.com/document/d/1l9nopR-M2ZGLFRTZ7nUzeXJCcvBHtfGyCVr07DPN_JY/pub for detail.

1, Thoughts

In sometimes, we need boot ubuntu system on a native UEFI 32-bit BIOS machine, but all existing OS including window/linux only provides EFI64-bit ISO image, the only exception is apple Mac OS. So it almost impossible to install any OS on a pure native UEFI 32-bit BIOS based system.
This document introduces how to make that image based on Qemu environment. The core idea is:
- Create a raw qemu image and use GPT as its partition
- Install ubuntu 12.04 server i386 in qemu legacy BIOS mode.
- Install grub-efi32 in installed ubuntu system.
- Build OVMF 32bit UEFI BIOS image
- Boot qemu via OVMF 32bit BIOS image
2, Prerequisite

Ubuntu 12.04 server iso in i386 arch downloaded from http://releases.ubuntu.com/precise/ubuntu-12.04.3-server-i386.iso 
Ubuntu develop machine
Install GCC4.6 as default compiler
Install qemu by “sudo apt-get install qemu”
Install iasl by “sudo apt-get install iasl”
Install build tools by “sudo apt-get install build-essential bison flex uuid-dev”
3, Steps

3.1 Create RAW GPT image and partitions

- Create a 2G RAW image file
“qemu-img create -f raw gpt.raw 2G”
- Create GPT partition table in disk:
        “sudo parted gpt.raw mklabel gpt”
- Create BiosGrub partition in disk, since legacy boot need this partition in a GPT disk (MBR no need).
        “sudo parted gpt.raw mkpart primary fat32 0% 100M”
- Create ESP(EFI System Partition), since UEFI boot need this partition for bootia32.efi file
        “sudo parted gpt.raw mkpart primary fat32 100M 200M”
        “sudo parted gpt.raw mkfs 2 fat32”
- Create rootfs
        “sudo parted gpt.raw mkpart primary ext2 200M 75%”
        “sudo parted gpt.raw mkfs 3 ext2”
- Create swap partition
        “sudo parted gpt.raw mkpart primary linux-swap 75% 100%”
        “sudo parted gpt.raw mkfs 4 linux-swap”
3.2 Install ubuntu server i386 via Qemu on Default Legacy BIOS

After above image created, now install ubuntu server i386 on GPT disk by following command:
“qemu-system-i386 -hda gpt.raw -m 1024 -cdrom ubuntu-12.04.3-server-i386.iso  -serial file:log_ia32.txt -boot d”
Note:
By default, the BIOS used by qemu is legacy BIOS. Because the ubuntu-12.04.3-server-i386 only support legacy boot.
“-boot d” means boot from cdrom.
When installing,
Set the partition 1 as “biosgrub” type.
Mount the partition 2 to /boot/efi.

After installation, booting into ubuntu i386 server still via legacy boot:
Remove “-boot d” from qemu startup script. So system would boot via hard disk instead of CDRom.
Press “e” in grub menu
Add boot parameters “console=ttyS0,115200n2 earlyprintk nomodeset loglevel=7”
Press F10 to continue boot
Note, you can see the whole boot log by “tail -f log_ia32.txt”, which is specified by above qemu start up command.

After first boot into ubuntu via legacy BIOS, then:
Add above additional boot parameter into grub:
vim /etc/default/grub
add “console=ttyS0,115200n8 earlyprintk nomodeset loglevel=7” in GRUB_CMDLINE_LINUX_DEFAULT macro.
sudo update-grub
-
3.3 Build UEFI 32bit BIOS for QEMU

Get the Source code from https://github.com/tianocore/edk2 by following GIT command:
- “git clone https://github.com/tianocore/edk2.git”
Build edk2 Linux Tool:
        - cd <edk2>
        - source edksetup.sh
        - cd <edk2>/BaseTools
        - make
Build IA32 BIOS:
- cd <edk2>
- source edksetup.sh
- build -p OvmfPkg/OvmfPkgIa32.dsc -D DEBUG_ON_SERIAL_PORT -b DEBUG -a IA32 -t GCC46
Note:
DEBUG_ON_SERIAL_PORT macro is used to output the BIOS debug info to serial file, so you can get log file on qemu via “-serial file:log.txt”
Get OVMF.fd file at <edk2>/Build/OvmfIa32/DEBUG_GCC46/FV/OVMF.fd
Test the new EFI IA32 BIOS image in qemu:
        “qemu-system-i386 -bios <edk2>/Build/OvmfIa32/DEBUG_GCC46/FV/OVMF.fd” -serial file:uefi_log.txt”
        see the UEFI BIOS output by “tail -f uefi_log.txt”

3.4 Convert ubuntu boot from legacy BIOS to UEFI 32bit BIOS

Refer 3.2, Boot ubuntu via Legacy BIOS first
In ubuntu terminal, install “grub-efi-ia32” package by
        “sudo apt-get install grub-efi-ia32”
Then, install grub-efi to /dev/sda disk by:
        “sudo grub-install /dev/sda”
Note:
- the grub.efi and grub.cfg will be installed into the second partition ESP(EFI System Partition) which has been mounted into /boot/efi node.
- By default, ubuntu will *not* create efi/boot/bootia32.efi file, but only create efi/ubuntu/ folder for grubia32.efi and boot.efi. Then use set variable to save them as default boot loader. But now the action of saving variable will be falied, because current OS is not EFI system.
Turn off qemu and restart qemu in UEFI mode via following command line:
        “qemu-system-i386 -bios <edk2>/Build/OvmfIa32/DEBUG_GCC46/FV/OVMF.fd -serial file:uefi_log.txt -hda gpt.raw”
        Note:
        - Use OVMF binaries built from above 3.3
        - Use gpt.raw system image from above 3.2
After reboot, you may find system can not boot ubuntu, but jump into EFI shell like below

        The reason is:
- In above step of “grub-install /dev/sda”, ubuntu will not create default EFI boot file like “efi/boot/bootia32.efi”, but only create efi/ubuntu/grubia32.efi” file. So EFI BIOS can not find the default boot file for continuing boot.
- Also in previous steps, ubuntu can not save EFI boot option via runtime variable service, because original boot environment is legacy boot but not EFI boot.
        The solution is:
        - In EFI shell, for fs0: disk:
                - Create EFI/boot folder
                - type “cp fs0:\efi\ubuntu\grubia32.efi fs0:\efi\boot\bootia32.efi
After reboot, system can boot into original ubuntu server via EFI 32 OVMF bios now~~~~
After boot, you can run “grub-install /dev/sda” again to save boot variable “ubuntu” into UEFI BIOS variable for future default boot as follows:

3.5 Create bootable USB device

Now we can create bootable USB device from the gpt.img with ubuntu system now.
Plug the USB disk in your work machine
“sudo dd if=gpt.raw of=/dev/sdb”
Verify the USB disk by qemu:
        “qemu-system-i386 -bios <edk2>/Build/OvmfIa32/DEBUG_GCC46/FV/OVMF.fd -serial file:uefi_log.txt -hda /dev/sdb”
