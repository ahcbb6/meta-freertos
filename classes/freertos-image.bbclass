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
IMGDEPLOYDIR ?= "${WORKDIR}/deploy-${PN}-image-complete"
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

do_image(){
  install ${D}/image.bin ${DEPLOYDIR}/${IMAGE_LINK_NAME}.bin
  install ${D}/image.elf ${DEPLOYDIR}/${IMAGE_LINK_NAME}.elf
}

do_image_complete(){
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

# Assure binaries, manifest and qemubootconf are populated on DEPLOY_DIR_IMAGE
do_image_complete[dirs] = "${TOPDIR}"
do_image_complete[umask] = "022"
SSTATETASKS += "do_image_complete"
SSTATE_SKIP_CREATION_task-image-complete = '1'
do_image_complete[sstate-inputdirs] = "${IMGDEPLOYDIR}"
do_image_complete[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_image_complete[stamp-extra-info] = "${MACHINE_ARCH}"
addtask do_image_complete after do_image before do_build

python do_image_complete_setscene () {
    sstate_setscene(d)
}
addtask do_image_complete_setscene

# This next part is necessary to trick the build system into thinking
# its building an image recipe so it generates the qemuboot.conf
addtask do_rootfs before do_image after do_install
addtask do_image after do_rootfs before do_build
addtask do_image_complete after do_image before do_build
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
    d.appendVarFlag('do_image', 'depends', extraimage_getdepends('do_populate_sysroot'))
}

# Add boot patterns to use with OE testimage infrastructure with the serial console
TESTIMAGE_BOOT_PATTERNS = "search_reached_prompt send_login_user search_login_succeeded search_cmd_finished"
# Look for FreeRTOS to check when the device has booted
TESTIMAGE_BOOT_PATTERNS[search_reached_prompt] = " FreeRTOS"
# Use carriage return as the user to "log in"
TESTIMAGE_BOOT_PATTERNS[send_login_user] = "\r"
# Use the string You entered to check if the "log in" was successful (which is what would be printed afterwards)
TESTIMAGE_BOOT_PATTERNS[search_login_succeeded] = "You entered"
# Use the string Unblocked to check if the "command" finished, in the Linux case this should look for a prompt
# In our case, this checks if the task has been Unblocked which is printed on the serial console after a command
TESTIMAGE_BOOT_PATTERNS[search_cmd_finished] = "Unblocked"

# We have to do = otherwise it tries to run the Linux tests from OpenEmbedded
TEST_SUITES = "freertos_echo"
