SUMMARY = "FreeRTOS application example to STM32 based microcontrollers"

# This app bundles its own copy of FreeRTOS, dont use layer provided FreeRTOS
FREERTOS_BUNDLE = "1"

# FreeRTOS Specifics
FREERTOS_VERSION = "FreeRTOSv10.3.1"
FREERTOS_SRC_DIR = "${S}/Middlewares/Third_Party/FreeRTOS/Source/"
LIC_FILES_CHKSUM = "file://${FREERTOS_SRC_DIR}/LICENSE;md5=50edf8d91b83164d9492fbbc09d25127"

# App Specifics
LIC_FILES_CHKSUM:append = " file://${S}/LICENSE;md5=a670e5d5245e0ffae9782ea5e22af84e"
LICENSE:append = " & MIT"

COMPATIBLE_MACHINE:stm32f446 = "stm32f446"


BAREMETAL_BINNAME = "FreeeRTOS-STM32-UART"

inherit freertos-image

SRCBRANCH = "main"
SRC_URI = "git://github.com/ahcbb6/FreeRTOS-STM32Demo.git;destsuffix=freertos;branch=${SRCBRANCH};protocol=https"
S = "${UNPACKDIR}/freertos"

SRCREV = "ba0f20b9e1d8b0b0d268bb09c848a50c3b8b6a29"

do_compile:prepend(){
    # Our Makefile requires us to override these variables
    export CFLAGS="${CFLAGS}"
    export SZ="${HOST_PREFIX}size"
    export AS="${CC} -x assembler-with-cpp"
    export CP="${OBJCOPY}"
    cd ${S}
}

B = "${S}/build"

# On top of the elf and binary, we also want the .hex file
FILES:${PN}:append = " \
    ${base_libdir}/firmware/${BAREMETAL_BINNAME}.hex \
"

do_install:append() {
    install -m 755 ${B}/${BAREMETAL_BINNAME}.hex ${D}/${base_libdir}/firmware/${BAREMETAL_BINNAME}.hex
}

do_image:append(){
    install -m 755 ${B}/${BAREMETAL_BINNAME}.hex ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.hex
}
