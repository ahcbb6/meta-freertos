SUMMARY = "FreeRTOS application example based on https://github.com/jkovacic/"

inherit freertos-app

# App can be replaced by using a different repo
SRC_URI += " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=app;destsuffix=app;branch=aehs29/app; \
"

SRCREV_FORMAT = "bsp_app"
SRCREV_app = "${AUTOREV}"

