SUMMARY = "FreeRTOS QEMU echo and periodic task demo"

# Use the FreeRTOS kernel fetched by the layer, not a copy bundled with the app.
FREERTOS_BUNDLE = "0"

inherit freertos-qemuvirt

SRC_URI += " \
    git://github.com/ahcbb6/FreeRTOS-Demo-OE.git;name=app;destsuffix=app;branch=main;protocol=https \
"
SRCREV_app = "93d2f45cd0cc6a043f0507a894912cd8cd248a64"
LIC_FILES_CHKSUM += "file://LICENSE;md5=84f28cbb4c7940fe70671601f2c750cb"

S = "${UNPACKDIR}/app"
B = "${S}"
BAREMETAL_BINNAME = "image"

# The following is only required for running bitbake freertos-demo -c testimage.
# Use serial-console boot patterns with OE's testimage infrastructure.
TESTIMAGE_BOOT_PATTERNS = "search_reached_prompt send_login_user search_login_succeeded search_cmd_finished"
# Look for Blocked... to check when the device is ready to receive input.
TESTIMAGE_BOOT_PATTERNS[search_reached_prompt] ?= "Blocked..."
# Use carriage return as the user to "log in".
TESTIMAGE_BOOT_PATTERNS[send_login_user] ?= "\r"
# The echoed input stands in for a successful login.
TESTIMAGE_BOOT_PATTERNS[search_login_succeeded] ?= "You entered"
# Unblocked marks command completion instead of the usual Linux shell prompt.
TESTIMAGE_BOOT_PATTERNS[search_cmd_finished] ?= "Unblocked"

# Select FreeRTOS tests rather than the default Linux runtime tests.
TEST_SUITES ?= "freertos_echo"
