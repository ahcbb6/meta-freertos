# FreeRTOS class
# This class is meant to be inherited by recipes for FreeRTOS apps
# It contains code that would be used by all of them, where every 
# recipe would just need to override certain parts
#
# We are getting the FreeRTOS source code from upstream
# We have a BSP repo where we get the portable code from there
# And we get the app code from a different repo 

FREERTOS_VERSION = "FreeRTOSv10.2.0"

LICENSE = "MIT"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

BSP_REPO ?= "../bsp"

SRC_URI = " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=bsp;destsuffix=bsp;branch=aehs29/bsp; \
    git://github.com/aws/amazon-freertos.git;name=freertos;destsuffix=freertos; \
"

SRC_URI[freertos.md5sum] = "36b71a9a2b9d26faa8386629f37101a1"
SRC_URI[freertos.sha256sum] = "e295c2197a1a04ec21fbe7e55e2dbd88b144c1b8c23b28e92ee724aa529da63d"


# FreeRTOS License
LIC_FILES_CHKSUM = "file://../freertos/LICENSE;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

# BSP repo License
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"



SRCREV_bsp ?= "${AUTOREV}"
SRCREV_freertos ?= "${AUTOREV}"

PV = "${FREERTOS_VERSION}+git${SRCPV}"

S="${WORKDIR}/bsp"

DEPENDS = "qemu-helper-native"

inherit deploy
do_deploy[dirs] = "${DEPLOYDIR} ${DEPLOY_DIR_IMAGE}"
DEPLOYDIR = "${IMGDEPLOYDIR}"

IMAGE_LINK_NAME ?= "freertos-image-${MACHINE}"

FILES_${PN} += "image.bin image.elf"

do_configure_prepend(){
  # Copy portable code from bsp repo into FreeRTOS source code
  cp -r ${WORKDIR}/bsp/portable/GCC/ARM926EJ-S/ ${WORKDIR}/freertos/lib/FreeRTOS/portable/GCC/ARM926EJ-S/
}


# QEMU crashes when FreeRTOS is built with optimizations, disable those for now
CFLAGS_remove = "-O2"

# We need to define the port were using, along with the FreeRTOS source code location
EXTRA_OEMAKE = "PORT=ARM926EJ-S FREERTOS_SRC=../freertos/lib/FreeRTOS/ 'CFLAGS=${CFLAGS} -I../freertos/lib/FreeRTOS/ -I../freertos/lib/include/ -I../freertos/lib/include/private/ -I${S}/drivers/include/'"

do_compile(){
  oe_runmake ${EXTRA_OEMAKE}
}

do_install(){
  install -m 755 ${B}/image.bin ${D}/image.bin
  install -m 755 ${B}/image.elf ${D}/image.elf
}

do_deploy(){
  install ${D}/image.bin ${DEPLOYDIR}/${IMAGE_LINK_NAME}.bin
  install ${D}/image.elf ${DEPLOYDIR}/${IMAGE_LINK_NAME}.elf
}

do_image(){
:
}

do_rootfs(){
:
}

# QEMU parameters
QB_SYSTEM_NAME = "qemu-system-arm"
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.bin"
QB_MEM = "-m 128"
QB_MACHINE = "-M versatilepb"
QB_OPT_APPEND = "-nographic"
QB_DEFAULT_FSTYPE = "bin"
QB_DTB = ""

# These are necessary to trick the build system into thinking
# its building an image recipe so it generates the qemuboot.conf
addtask do_deploy after do_write_qemuboot_conf before do_build
addtask do_rootfs before do_deploy after do_install
addtask do_image after do_rootfs before do_build
inherit qemuboot
