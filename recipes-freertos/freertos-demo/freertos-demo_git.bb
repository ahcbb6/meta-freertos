SUMMARY = "FreeRTOS application example based on https://github.com/jkovacic/"

BAREMETAL_BINNAME = "image"

# Specify we want bitbake to use the FreeRTOS source code provided by the layer
FREERTOS_BUNDLE = "0"

LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=8f5b865d5179a4a0d9037aebbd00fc2e"

inherit freertos-image

S="${WORKDIR}/app"

# App can be replaced by using a different repo
SRC_URI += " \
    git://github.com/ahcbb6/FreeRTOS-GCC-ARM926ejs.git;name=app;destsuffix=app;branch=meta-freertos;protocol=https \
    file://use-newlib-as-libc.patch \
"

SRCREV_FORMAT = "freertos_app"
SRCREV_app = "4b08f3a14bc283245d0e86a912778ea5af4f2b60"


EXTRA_OEMAKE += "APP_SRC=${S}/Demo/ 'STAGING_LIBDIR=${STAGING_LIBDIR}'"

do_configure:prepend(){
  # Copy portable code from app repo into FreeRTOS source code
  cp -r ${S}/FreeRTOS/Source/portable/GCC/ARM926EJ-S/ ${FREERTOS_KERNEL_SRC}/portable/GCC/ARM926EJ-S/
}



# QEMU crashes when FreeRTOS is built with optimizations, disable those for now
FULL_OPTIMIZATION = " -pipe ${DEBUG_FLAGS}"


# CFLAGS required for this specific PORT
CFLAGS:append = " -I${S}/drivers/include/"

# Define the PORT we are using
EXTRA_OEMAKE:append = " PORT=ARM926EJ-S"

# QEMU parameters specific for this PORT
QB_SYSTEM_NAME = "qemu-system-arm"
QB_MACHINE = "-M versatilepb"
QB_DTB = ""

# Only create one serial console, so QEMUrunner can communicate with the target
SERIAL_CONSOLES="115200;ttyAMA0"


#
# The following is only required for running bitbake -c testimage
#
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
