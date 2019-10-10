# FreeRTOS class
# This class is meant to be inherited by recipes for FreeRTOS apps
# It contains code that would be used by all of them, where every 
# recipe would just need to override certain parts
#
# We are getting the FreeRTOS source code from upstream
# We have a BSP repo where we get the portable code from there
# And we get the app code from a different repo 

# FreeRTOS kernel version (FreeRTOS.h)
FREERTOS_VERSION = "FreeRTOSv10.2.1"

LICENSE = "MIT"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

BSP_REPO ?= "../bsp"

SRC_URI = " \
    git://github.com/aws/amazon-freertos.git;name=freertos;destsuffix=freertos; \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=bsp;destsuffix=bsp;branch=aehs29/bsp; \
"

SRCREV_FORMAT ?= "freertos_bsp"

# FreeRTOS License
LIC_FILES_CHKSUM = "file://../freertos/LICENSE;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

# BSP repo License
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"



SRCREV_bsp ?= "d2b58036f77e3470af56854602c1d701021c2fb9"
SRCREV_freertos ?= "5bee12b2cd5ddbf2c6b3bf394ea41649999a1453"

PV = "${FREERTOS_VERSION}+git${SRCPV}"

S="${WORKDIR}/bsp"


inherit deploy
do_deploy[dirs] = "${DEPLOYDIR} ${DEPLOY_DIR_IMAGE}"
DEPLOYDIR = "${IMGDEPLOYDIR}"

IMAGE_LINK_NAME ?= "freertos-image-${MACHINE}"

FILES_${PN} += "image.bin image.elf"

do_configure_prepend(){
  # Copy portable code from bsp repo into FreeRTOS source code
  cp -r ${WORKDIR}/bsp/portable/GCC/ARM926EJ-S/ ${WORKDIR}/freertos/freertos_kernel/portable/GCC/ARM926EJ-S/
}


# QEMU crashes when FreeRTOS is built with optimizations, disable those for now
CFLAGS_remove = "-O2"

# We need to define the port were using, along with the FreeRTOS source code location
EXTRA_OEMAKE = "PORT=ARM926EJ-S FREERTOS_SRC=../freertos/freertos_kernel/ 'CFLAGS=${CFLAGS} -I../freertos/freertos_kernel -I../freertos/freertos_kernel/include/ -I${S}/drivers/include/'"

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

# This next part is necessary to trick the build system into thinking
# its building an image recipe so it generates the qemuboot.conf
addtask do_deploy after do_write_qemuboot_conf before do_build
addtask do_rootfs before do_deploy after do_install
addtask do_image after do_rootfs before do_build
inherit qemuboot


# Based on image.bbclass to make sure we build qemu
python(){
    # do_addto_recipe_sysroot doesnt exist for all recipes, but we need it to have
    # /usr/bin on recipe-sysroot (qemu) populated
    def extraimage_getdepends(task):
        deps = ""
        for dep in (d.getVar('EXTRA_IMAGEDEPENDS') or "").split():
            # Make sure we only add it for qemu
            if 'qemu' in dep:
                deps += " %s:%s" % (dep, task)
        return deps
    d.appendVarFlag('do_image', 'depends', extraimage_getdepends('do_addto_recipe_sysroot'))
}
