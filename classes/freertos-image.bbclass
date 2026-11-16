# FreeRTOS image class
#
# This class is meant to be inherited by recipes for FreeRTOS applications.
# It contains code that would be used by all of them, where every 
# recipe would just need to override certain parts.
#
# For scalability purposes, code within this class focuses on the
# "image" wiring that makes apps work properly with openembedded-core
# infrastructure.
#
# We are getting the FreeRTOS source code from upstream (this class)
# And we get the app code from a different repo (app recipe)

LICENSE = "MIT"
# FreeRTOS License, careful here, the gitsm fetcher does not work properly with license checking
# double check this manually after an upgrade
LIC_FILES_CHKSUM ?= "file://${FREERTOS_SRC_DIR}/LICENSE.md;md5=7ae2be7fb1637141840314b51970a9f7"


# FreeRTOS kernel version (FreeRTOS.h)
FREERTOS_VERSION ?= "FreeRTOSv11.3.3"

SRCBRANCH ?= "main"
# Kernel release tags are not necessarily reachable from main.
FREERTOS_SRC_URI ?= "gitsm://github.com/FreeRTOS/FreeRTOS-Kernel.git;name=freertos;destsuffix=freertos;nobranch=1;protocol=https"

SRCREV_FORMAT ?= "freertos_app"
SRCREV_freertos ?= "89592801dd8b73329a7583719b7e3567b50910e5"
PV = "${FREERTOS_VERSION}+git${SRCPV}"

# Within the repo where is the kernel located
FREERTOS_SRC_DIR ?= "${UNPACKDIR}/freertos"
FREERTOS_KERNEL_SRC ?= "${FREERTOS_SRC_DIR}/"

DEBUG_PREFIX_MAP:append = " -fdebug-prefix-map=${UNPACKDIR}=  -fmacro-prefix-map=${UNPACKDIR}="


# RTOS App may already include FreeRTOS source code, set to 0 by default to use our own copy of FreeRTOS
FREERTOS_BUNDLE ?= "0"

# Download our own copy of FreeRTOS
SRC_URI:append = "${@bb.utils.contains('FREERTOS_BUNDLE', '0', ' ${FREERTOS_SRC_URI}', '', d)}"
# Extra CFLAGS required for FreeRTOS include files
CFLAGS:append = "${@bb.utils.contains('FREERTOS_BUNDLE', '0', '  -I${FREERTOS_KERNEL_SRC} -I${FREERTOS_KERNEL_SRC}/include/', '', d)}"
# Pass FreeRTOS source code location
EXTRA_OEMAKE = "${@bb.utils.contains("FREERTOS_BUNDLE", "0", " FREERTOS_SRC=${FREERTOS_KERNEL_SRC} CFLAGS='${CFLAGS}'", "", d)}"


# Image defaults
IMAGE_BASENAME ?= "freertos-image"
BAREMETAL_BINNAME ?= "${IMAGE_BASENAME}"
IMAGE_LINK_NAME ?= "${IMAGE_BASENAME}-${MACHINE}"


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


## Default Tasks
do_compile(){
    oe_runmake ${EXTRA_OEMAKE}
}

do_install(){
  install -d ${D}/${base_libdir}/firmware
  install -m 755 ${B}/${BAREMETAL_BINNAME}.bin ${D}/${base_libdir}/firmware/${BAREMETAL_BINNAME}.bin
  install -m 755 ${B}/${BAREMETAL_BINNAME}.elf ${D}/${base_libdir}/firmware/${BAREMETAL_BINNAME}.elf
}
