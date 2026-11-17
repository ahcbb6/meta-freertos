# Shared BSP integration for OE-Core's ARM QEMU virt machines.

inherit freertos-image

COMPATIBLE_MACHINE = "^(qemuarm|qemuarm64)$"
PACKAGE_ARCH = "${MACHINE_ARCH}"

FILESEXTRAPATHS:prepend := "${FREERTOS_LAYERDIR}/classes/files:"

FREERTOS_BSP_SRC ?= "${UNPACKDIR}/bsp"
SRC_URI:append = " git://github.com/ahcbb6/FreeRTOS-Demo-OE-BSP.git;name=bsp;destsuffix=bsp;branch=main;protocol=https"
SRC_URI:append:qemuarm64 = " file://0001-ARM_AARCH64-include-string.h-for-memset.patch;patchdir=${FREERTOS_SRC_DIR}"
SRCREV_bsp ?= "cd2843c7911ba062ce7745e8da2265ecc32dc9ec"
SRCREV_FORMAT = "freertos_app_bsp"
LIC_FILES_CHKSUM:append = " file://${FREERTOS_BSP_SRC}/LICENSE;md5=84f28cbb4c7940fe70671601f2c750cb"

# The IRQ handlers do not preserve FP/SIMD registers unless switching tasks.
CFLAGS:append = " -ffreestanding -fno-stack-protector -fno-pie -mgeneral-regs-only"
CFLAGS:append:qemuarm64 = " -DGUEST"
EXTRA_OEMAKE += "BSP_SRC='${FREERTOS_BSP_SRC}' ARCH='${TARGET_ARCH}' CC='${CC}' OBJCOPY='${OBJCOPY}' LDFLAGS='${LDFLAGS}'"

# Both upstream ports use the GICv2 MMIO interface without a hypervisor.
QB_MACHINE = "-machine virt,gic-version=2,virtualization=off,secure=off"
QB_MACHINE:append:qemuarm = ",highmem=off"
QB_SMP = "-smp 1"
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.elf"
QB_DEFAULT_FSTYPE = "elf"
QB_ROOTFS = "none"
QB_SERIAL_OPT = ""
QB_TCPSERIAL_OPT = ""
SERIAL_CONSOLES = "115200;ttyAMA0"
