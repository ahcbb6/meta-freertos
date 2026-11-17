# Shared BSP integration for OE-Core's QEMU virt machines.

inherit freertos-image

COMPATIBLE_MACHINE = "^(qemuarm|qemuarm64|qemuriscv32|qemuriscv64)$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

FILESEXTRAPATHS:prepend := "${FREERTOS_LAYERDIR}/classes/files:"

FREERTOS_BSP_SRC ?= "${UNPACKDIR}/bsp"
SRC_URI:append = " git://github.com/ahcbb6/FreeRTOS-Demo-OE-BSP.git;name=bsp;destsuffix=bsp;branch=main;protocol=https"
SRC_URI:append:qemuarm64 = " file://0001-ARM_AARCH64-include-string.h-for-memset.patch;patchdir=${FREERTOS_SRC_DIR}"
SRCREV_bsp ?= "7c519e66046ed8beb4b3872d12030da51b7643b5"
SRCREV_FORMAT = "freertos_app_bsp"
LIC_FILES_CHKSUM:append = " file://${FREERTOS_BSP_SRC}/LICENSE;md5=84f28cbb4c7940fe70671601f2c750cb"

# The IRQ handlers do not preserve FP/SIMD registers unless switching tasks.
CFLAGS:append = " -ffreestanding -fno-stack-protector -fno-pie"
CFLAGS:append:qemuarm = " -mgeneral-regs-only"
CFLAGS:append:qemuarm64 = " -mgeneral-regs-only"
CFLAGS:append:qemuarm64 = " -DGUEST"
EXTRA_OEMAKE += "BSP_SRC='${FREERTOS_BSP_SRC}' ARCH='${TARGET_ARCH}' CC='${CC}' OBJCOPY='${OBJCOPY}' LDFLAGS='${LDFLAGS}'"

# ARM ports use GICv2; RISC-V boots directly in machine mode.
QB_MACHINE = "-machine virt,gic-version=2,virtualization=off,secure=off"
QB_MACHINE:append:qemuarm = ",highmem=off"
QB_MACHINE:qemuriscv64 = "-machine virt"
QB_MACHINE:qemuriscv32 = "-machine virt"
QB_CPU:qemuriscv64 = "-cpu rv64"
QB_CPU:qemuriscv32 = "-cpu rv32"
QB_KERNEL_CMDLINE_APPEND:qemuriscv64 = ""
QB_KERNEL_CMDLINE_APPEND:qemuriscv32 = ""
EXTRA_IMAGEDEPENDS:remove:qemuriscv64 = "opensbi u-boot"
EXTRA_IMAGEDEPENDS:remove:qemuriscv32 = "opensbi u-boot"
QB_SMP = "-smp 1"
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.elf"
QB_DEFAULT_FSTYPE = "elf"
QB_ROOTFS = "none"
QB_SERIAL_OPT = ""
QB_TCPSERIAL_OPT = ""
SERIAL_CONSOLES = "115200;ttyAMA0"
SERIAL_CONSOLES:qemuriscv64 = "115200;ttyS0"
SERIAL_CONSOLES:qemuriscv32 = "115200;ttyS0"
