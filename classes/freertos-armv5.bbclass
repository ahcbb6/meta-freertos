# FreeRTOS ARM926ejs bsp class
#
# This class contains code that could potentially change depending
# on the specific PORT for which FreeRTOS is being built for, but
# it still inherits the freertos-image class which contains the
# "image" wiring for oe-core to work properly.
# If other PORTs were to be used, a class similar to this one
# should potentially be used.

inherit freertos-image

BSP_REPO ?= "../bsp"

SRC_URI_append = " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=bsp;destsuffix=bsp;branch=aehs29/bsp; \
"

# BSP repo License
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

SRCREV_bsp ?= "fa926b03ad8f3469c22292c8f9bff9a03dbaf555"

S="${WORKDIR}/bsp"


do_configure_prepend(){
  # Copy portable code from bsp repo into FreeRTOS source code
  cp -r ${WORKDIR}/bsp/portable/GCC/ARM926EJ-S/ ${FREERTOS_KERNEL_SRC}/portable/GCC/ARM926EJ-S/
}

# CFLAGS required for this specific PORT
CFLAGS_append = " -I${S}/drivers/include/"

# Define the PORT we are using
EXTRA_OEMAKE_append = " PORT=ARM926EJ-S"

# QEMU parameters specific for this PORT
QB_SYSTEM_NAME = "qemu-system-arm"
QB_MACHINE = "-M versatilepb"
QB_DTB = ""

# Only create one serial console, so QEMUrunner can communicate with the target
SERIAL_CONSOLES="115200;ttyAMA0"
