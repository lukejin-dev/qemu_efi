@echo off

if not defined QEMU_DIR (
   @echo "please specify the qemu binary directory for macro QEMU_DIR"
   @goto end
)

set top=%~dp0
set bios_file=%top%\ovmf\ken-X64\bios.bin
set disk_file=%top%\images\ubuntu64_gpt.raw
set compressed_disk_file=%disk_file%.xz
set options=-hda %disk_file% -m 1024 -serial file:log64.txt -vga cirrus

:check_parameter
if "%1"=="" goto no_parameter
if "%1"=="efi" goto efi_boot
if "%1"=="legacy" goto legacy_boot
goto no_parameter

:efi_boot
set bios_flag=-bios %bios_file%
goto start

:legacy_boot
set bios_flag=
goto start

:start
set qemu_cmd= %QEMU_DIR%\qemu-system-x86_64.exe
set addtional=%2

%qemu_cmd% %options% %bios_flag% %addtional%
goto end

:no_parameter
@echo "please specify efi or legacy"
goto end

:end