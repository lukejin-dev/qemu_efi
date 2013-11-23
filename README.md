qemu_efi
========
In sometimes, we need boot ubuntu system on a native UEFI 32-bit BIOS machine, but all existing OS including window/linux only provides EFI64-bit ISO image, the only exception is apple Mac OS. So it almost impossible to install any OS on a pure native UEFI 32-bit BIOS based system.

So this package provides:

- 1) Tools to create raw GPT image
- 2) Pre-build OVMF 32/64-bit UEFI BIOS binary with debug build and serial output
- 3) The image ubuntu32_gpt.raw.xz for ubuntu server 32bit which can be boot with 2) OVMF UEFI BIOS IA32 binary in qemu.
- 4) The image ubuntu64_gpt.raw.xz for ubuntu server 64bit which can be boot with 2) OVMF UEFI BIOS X64 binary in qemu. 

You can use the RAW image in above 3 & 4 to create USB boot disk to boot with UEFI 32-bit BIOS or UEFI 64-bit BIOS.

Beyond that, you can use above 3) & 4) to do whole boot path debug from BIOS to OS for native UEFI 32&64, since all serial output are redirected to a single log file.

Please reference https://docs.google.com/document/d/1l9nopR-M2ZGLFRTZ7nUzeXJCcvBHtfGyCVr07DPN_JY/pub for detail.


Play Steps:
===========
a) Get ubuntu32_gpt.raw.xz and ubuntu64_gpt.raw.xz from 
   Because github.com disallow a single file exceed 100M, so ...
   Also you can build/install ubuntu32_gpt.raw and ubuntu64_gpt.raw by self according to the steps in above reference link.
   
b) Put ubuntu32_gpt.raw.xz and ubuntu64_gpt.raw.xz to images folder.

c) Run "qemu_linux32.sh efi" to start the debug version BIOS + ubuntu from the disk image ubuntu32_gpt.raw

d) Run "qemu_linux64.sh efi" to start the debug version BIOS + ubuntu from the disk image ubuntu64_gpt.raw

Create USB disk for ubuntu image
================================
(Assume your usb disk is located at /dev/sdb in host machine)

<code>dd if=images/ubuntu32_gpt.raw of=/dev/sdb</code> <br>
<code>dd if=images/ubuntu64_gpt.raw of=/dev/sdb</code>

    
