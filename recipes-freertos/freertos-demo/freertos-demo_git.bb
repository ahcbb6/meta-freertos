SUMMARY = "FreeRTOS application example based on https://github.com/jkovacic/"

inherit freertos-app

# App can be replaced by using a different repo
SRC_URI += " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=app;destsuffix=app;branch=aehs29/app2; \
    file://use-newlib-as-libc.patch \
"

SRCREV_FORMAT = "freertos_bsp_app"
SRCREV_app = "5353ca1b308210b73c2cb4573eb2d02904c96622"


EXTRA_OEMAKE += "APP_SRC=../app/Demo/ 'STAGING_LIBDIR=${STAGING_LIBDIR}'"
