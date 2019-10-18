# FreeRTOS image class
#
# This class is meant to be inherited by recipes for FreeRTOS apps
# It contains code that would be used by all of them, where every 
# recipe would just need to override certain parts.
#
# For scalability purposes, code within this class focuses on the
# "image" wiring that makes apps work properly with openembedded-core
# infrastructure.

# We are getting the FreeRTOS source code from upstream (this class)
# We have a BSP repo where we get the portable code from (bsp class)
# And we get the app code from a different repo (app recipe)

# FreeRTOS kernel version (FreeRTOS.h)
FREERTOS_VERSION = "FreeRTOSv10.2.1"

LICENSE = "MIT"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = " \
    git://github.com/aws/amazon-freertos.git;name=freertos;destsuffix=freertos; \
"

SRCREV_FORMAT ?= "freertos_bsp"

# FreeRTOS License
LIC_FILES_CHKSUM = "file://../freertos/LICENSE;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

SRCREV_freertos ?= "5bee12b2cd5ddbf2c6b3bf394ea41649999a1453"

PV = "${FREERTOS_VERSION}+git${SRCPV}"

FREERTOS_KERNEL_SRC = "${WORKDIR}/freertos/freertos_kernel/"

inherit rootfs-postcommands
inherit deploy
do_deploy[dirs] = "${DEPLOYDIR} ${DEPLOY_DIR_IMAGE}"
DEPLOYDIR = "${IMGDEPLOYDIR}"
do_rootfs[dirs] = "${DEPLOYDIR} ${DEPLOY_DIR_IMAGE}"
IMAGE_LINK_NAME ?= "freertos-image-${MACHINE}"
IMAGE_NAME_SUFFIX ?= ""

# QEMU crashes when FreeRTOS is built with optimizations, disable those for now
CFLAGS_remove = "-O2"

# Extra CFLAGS required for FreeRTOS include files
CFLAGS_append = " -I${FREERTOS_KERNEL_SRC} -I${FREERTOS_KERNEL_SRC}/include/"

# We need to define the FreeRTOS source code location, the port we'll be using
# should be defined on the specific bsp class
EXTRA_OEMAKE = " FREERTOS_SRC=${FREERTOS_KERNEL_SRC} 'CFLAGS=${CFLAGS}'"

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

FILES_${PN} += "image.bin image.elf"

python do_rootfs(){
    from oe.utils import execute_pre_post_process
    from pathlib import Path

    # Write empty manifest testdate file
    deploy_dir = d.getVar('DEPLOYDIR')
    link_name = d.getVar('IMAGE_LINK_NAME')
    manifest_name = d.getVar('IMAGE_MANIFEST')

    Path(manifest_name).touch()
    if os.path.exists(manifest_name) and link_name:
            manifest_link = deploy_dir + "/" + link_name + ".manifest"
            if os.path.lexists(manifest_link):
                os.remove(manifest_link)
            os.symlink(os.path.basename(manifest_name), manifest_link)
    execute_pre_post_process(d, d.getVar('ROOTFS_POSTPROCESS_COMMAND'))
}

# QEMU generic FreeRTOS parameters
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.bin"
QB_MEM = "-m 128"
QB_OPT_APPEND = "-nographic"
QB_DEFAULT_FSTYPE = "bin"

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
