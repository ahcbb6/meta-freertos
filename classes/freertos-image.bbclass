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
FREERTOS_VERSION = "FreeRTOSv10.4.3"
SRCBRANCH = "202012-LTS"

LICENSE = "MIT"

# FreeRTOS License, careful here, the gitsm fetcher does not work properly with license checking
# double check this manually after an upgrade
LIC_FILES_CHKSUM = "file://../freertos/LICENSE;md5=7ae2be7fb1637141840314b51970a9f7"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = " \
    gitsm://github.com/FreeRTOS/FreeRTOS-LTS.git;name=freertos;destsuffix=freertos;branch=${SRCBRANCH} \
"

SRCREV_FORMAT ?= "freertos_bsp"
SRCREV_freertos ?= "1bb18c8dfbf8f0445e873b20cec7d6091771f9e9"

PV = "${FREERTOS_VERSION}+git${SRCPV}"

FREERTOS_KERNEL_SRC = "${WORKDIR}/freertos/FreeRTOS/FreeRTOS-Kernel/"

IMAGE_BASENAME = "freertos-image"
BAREMETAL_BINNAME ?= "${IMAGE_BASENAME}"
IMAGE_LINK_NAME ?= "${IMAGE_BASENAME}-${MACHINE}"


# QEMU crashes when FreeRTOS is built with optimizations, disable those for now
CFLAGS:remove = "-O2"

# Extra CFLAGS required for FreeRTOS include files
CFLAGS:append = " -I${FREERTOS_KERNEL_SRC} -I${FREERTOS_KERNEL_SRC}/include/"

# We need to define the FreeRTOS source code location, the port we'll be using
# should be defined on the specific bsp class
EXTRA_OEMAKE = " FREERTOS_SRC=${FREERTOS_KERNEL_SRC} 'CFLAGS=${CFLAGS}'"

do_compile(){
  oe_runmake ${EXTRA_OEMAKE}
}

do_install(){
  install -d ${D}/${base_libdir}/firmware
  install -m 755 ${B}/image.bin ${D}/${base_libdir}/firmware/${BAREMETAL_BINNAME}.bin
  install -m 755 ${B}/image.elf ${D}/${base_libdir}/firmware/${BAREMETAL_BINNAME}.elf
}


FILES:${PN}:append = " \
    ${base_libdir}/firmware/${BAREMETAL_BINNAME}.elf \
    ${base_libdir}/firmware/${BAREMETAL_BINNAME}.bin \
"

# QEMU generic FreeRTOS parameters
QB_DEFAULT_KERNEL = "${IMAGE_LINK_NAME}.bin"
QB_MEM = "-m 128"
QB_OPT_APPEND = "-nographic"
QB_DEFAULT_FSTYPE = "bin"

inherit baremetal-image

# Add boot patterns to use with OE testimage infrastructure with the serial console
TESTIMAGE_BOOT_PATTERNS = "search_reached_prompt send_login_user search_login_succeeded search_cmd_finished"
# Look for Blocked... to check when the device has booted and its ready to receive an input
TESTIMAGE_BOOT_PATTERNS[search_reached_prompt] ?= "Blocked..."
# Use carriage return as the user to "log in"
TESTIMAGE_BOOT_PATTERNS[send_login_user] ?= "\r"
# Use the string You entered to check if the "log in" was successful (which is what would be printed afterwards)
TESTIMAGE_BOOT_PATTERNS[search_login_succeeded] ?= "You entered"
# Use the string Unblocked to check if the "command" finished, in the Linux case this should look for a prompt
# In our case, this checks if the task has been Unblocked which is printed on the serial console after a command
TESTIMAGE_BOOT_PATTERNS[search_cmd_finished] ?= "Unblocked"

# We have to do = otherwise it tries to run the Linux tests from OpenEmbedded, this needs to be fixed upstream
TEST_SUITES ?= "freertos_echo"
