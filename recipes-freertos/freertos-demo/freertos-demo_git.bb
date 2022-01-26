SUMMARY = "FreeRTOS application example based on https://github.com/jkovacic/"

inherit freertos-armv5

# App can be replaced by using a different repo
SRC_URI += " \
    git://github.com/aehs29/FreeRTOS-GCC-ARM926ejs.git;name=app;destsuffix=app;branch=aehs29/application;protocol=https \
    file://use-newlib-as-libc.patch \
"

SRCREV_FORMAT = "freertos_bsp_app"
SRCREV_app = "af7c1b0cfcee98548f52ae5b1630b1251e9bd307"


EXTRA_OEMAKE += "APP_SRC=../app/Demo/ 'STAGING_LIBDIR=${STAGING_LIBDIR}'"
