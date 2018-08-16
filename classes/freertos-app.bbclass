# FreeRTOS class
# This class is meant to be inherited by recipes for FreeRTOS apps
# It contains code that would be used by all of them, where every 
# recipe would just need to override certain parts
#
# We are getting the FreeRTOS source code from upstream
# We have a BSP repo where we get the portable code from there
# And we get the app code from a different repo 



LICENSE = "MIT"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
FREERTOS_VERSION = "FreeRTOSv10.0.0"
BSP_REPO ?= "../bsp"

SRC_URI = " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=bsp;destsuffix=bsp;branch=aehs29/bsp; \
    https://sourceforge.net/projects/freertos/files/FreeRTOS/V10.0.0/${FREERTOS_VERSION}.zip;name=freertos; \
"
SRC_URI[freertos.md5sum] = "fc707bb965b1d3d59c1a9ed54e8a660f"
SRC_URI[freertos.sha256sum] = "d58a7e5bb4223b4dc9f73e12c403ebefeee9c423fbb56e19200b5edd894b4cd1"

# FreeRTOS License
LIC_FILES_CHKSUM = "file://../${FREERTOS_VERSION}/FreeRTOS/License/license.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

# BSP repo License
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

# FreeRTOS 10.0.1
#SRC_URI[md5sum] = "3d2d74725abe2933a960d7ee1c35456a"
#SRC_URI[sha256sum] = "5d04f890e1fa077646c9212371faf4445ca84e62f83274d37290ade949d3fc29"


SRCREV_bsp ?= "${AUTOREV}"

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
  cp -r ${WORKDIR}/bsp/portable/GCC/ARM926EJ-S/ ${WORKDIR}/${FREERTOS_VERSION}/FreeRTOS/Source/portable/GCC/ARM926EJ-S/
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

# Qemu parameters
QB_SYSTEM_NAME = "qemu-system-arm"
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.bin"
QB_MEM = "-m 128"
QB_MACHINE = "-M versatilepb"
QB_OPT_APPEND = "-nographic"
QB_DEFAULT_FSTYPE = "bin"
QB_DTB = ""

# These are necessary to trick the build system into thinking
# its building an image recipe so it generates the qemuboot.conf
addtask do_deploy after do_install before do_build
addtask do_rootfs before do_deploy after do_install
addtask do_image after do_rootfs before do_build
inherit qemuboot
