SUMMARY = "FreeRTOS application example based on https://github.com/jkovacic/"

# This app is the same as the one from the above repo,
# the only change is that this example is built locally
# istead of cloning from git

inherit freertos-app

# App can be replaced by using a different repo
SRC_URI += " \
    file://FreeRTOSConfig.h  \
    file://app_config.h \
    file://init.c \
    file://main.c \
    file://print.c \
    file://print.h \
    file://receive.c \
    file://receive.h \
    file://startup.s \
    file://LICENSE.txt \
    file://use-newlib-as-libc.patch \
"

EXTRA_OEMAKE += "APP_SRC=${WORKDIR}/ 'STAGING_LIBDIR=${STAGING_LIBDIR}'"
