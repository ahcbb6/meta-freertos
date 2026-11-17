# meta-freertos
FreeRTOS distro layer compatible with OpenEmbedded

Currently supported BSPs:
- QEMUARM (OE-Core `qemuarm`, Cortex-A15 on `virt`, single core)
- QEMUARM64 (OE-Core `qemuarm64`, Cortex-A57 on `virt`, single core)
- STM32F446 (ST Nucleo board)
- Raspberry Pi Pico (via the [meta-raspberrypi-baremetal](https://github.com/ahcbb6/meta-raspberrypi-baremetal) layer)

For building instructions for the Raspberry Pi Pico, refer to the
[meta-raspberrypi-baremetal layer documentation](https://github.com/ahcbb6/meta-raspberrypi-baremetal/blob/master/README.md).

## Build Status

| master  | [![Build Status][masterbadge]][masterpipeline]   |


[masterbadge]: https://github.com/ahcbb6/meta-freertos/actions/workflows/freertos.yml/badge.svg?branch=master
[masterpipeline]: https://github.com/ahcbb6/meta-freertos/actions/workflows/freertos.yml?query=branch%3Amaster


## Dependencies

This layer depends on:

     URI: https://git.openembedded.org/bitbake
     branch: master

     URI: https://git.openembedded.org/openembedded-core
     branch: master



## License
This layer has an MIT license (see [LICENSE](LICENSE)). The QEMU demo fetches
[FreeRTOS-Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel),
[FreeRTOS-Demo-OE-BSP](https://github.com/ahcbb6/FreeRTOS-Demo-OE-BSP), and
[FreeRTOS-Demo-OE](https://github.com/ahcbb6/FreeRTOS-Demo-OE), each with
its own license.


## FreeRTOS build setup

1.- Clone the required repositories
```bash
$ git clone https://git.openembedded.org/bitbake
$ git clone https://git.openembedded.org/openembedded-core
$ git clone https://github.com/ahcbb6/meta-freertos.git
```
2.- Add meta-freertos to your bblayers.conf
```bash
$ source openembedded-core/oe-init-build-env
$ bitbake-layers add-layer meta-freertos
```
3.- Add the required variables to your local.conf
```bash
$ echo "DISTRO = \"freertos\"" >> ./conf/local.conf
# If building for QEMU ARMv7 use:
$ echo "MACHINE = \"qemuarm\"" >> ./conf/local.conf
# If, instead, building for QEMU AArch64 use:
$ echo "MACHINE = \"qemuarm64\"" >> ./conf/local.conf
# If, instead, building for STM32 use:
$ echo "MACHINE = \"stm32f446\"" >> ./conf/local.conf
```

## Build a FreeRTOS demo as a standalone application:
4.- Build a sample FreeRTOS standalone application:
```bash
# For QEMU:
$ bitbake freertos-demo
# For STM32:
$ bitbake freertos-demo-stm32
```
5.- Run the application on QEMU (or flash the .hex file on the deploy directory for STM32):
```bash
$ runqemu nographic
```

After running runqemu you should be able to see the output of the application on QEMU and interact with it.

The `qemuarm` and `qemuarm64` demos share application tasks, QEMU `virt`
UART/GICv2 drivers, timer scheduling, configuration, and linker layout.
Only startup, exception vectors, register access, and the upstream kernel port
differ: `ARM_CA9` for Cortex-A15 and `ARM_AARCH64` at EL1 for Cortex-A57.
The demo uses the architectural physical timer and PL011 console. It echoes
printable ASCII input; carriage return and line feed each produce
`You entered: ""`, while other non-printable bytes are ignored. It prints
`Periodic task 10 secs` every ten seconds. Both
QEMU machines use the same `freertos-demo` target and publish ELF, binary, and
QEMU boot configuration artifacts in CI. Both `virt` boot configurations select
the ELF image so QEMU uses its linked entry point.

The application is fetched from
[FreeRTOS-Demo-OE](https://github.com/ahcbb6/FreeRTOS-Demo-OE).
The reusable `freertos-qemuvirt` class fetches board support from
[FreeRTOS-Demo-OE-BSP](https://github.com/ahcbb6/FreeRTOS-Demo-OE-BSP), selects
the architecture, and provides compiler flags and QEMU integration. It inherits
`freertos-image`, which fetches the upstream kernel separately. Other
applications can inherit `freertos-qemuvirt` to reuse the same BSP.

To run the echo and periodic-output runtime tests, add these settings to
`local.conf` and run `bitbake freertos-demo -c testimage`:
```bitbake
IMAGE_CLASSES += "testimage"
IMAGE_FEATURES += "allow-empty-password empty-root-password allow-root-login"
TEST_SUITES = "freertos_echo freertos_periodic"
```

Sample output on either QEMU machine:
```bash
FreeRTOS V11.3.3 on QEMU virt
Waiting For Notification - Blocked...
You entered: "~"
Unblocked
Waiting For Notification - Blocked...
Periodic task 10 secs
```


## Build Linux along with FreeRTOS (Linux on qemuarm64 and FreeRTOS on qemuarm):
(First 3 steps still apply)

4.- Enable multiconfig builds on your local.conf
```bash
$ echo "BBMULTICONFIG = \"dummy-arm64\"" >> ./conf/local.conf
$ echo "MACHINE = \"qemuarm\"" >> ./conf/local.conf
```
5.- Create a multiconfig dependency so freertos gets built automatically when building Linux
```bash
$ echo "do_image[mcdepends] = \"mc:dummy-arm64::freertos-demo:do_image\"" >> ./conf/local.conf
```
6.- Build Linux image and get a FreeRTOS demo for free!
```bash
$ bitbake mc:dummy-arm64:core-image-minimal
```
7.- Run the FreeRTOS application on QEMU:
```bash
$ runqemu nographic
```
8.- Run the Linux image on QEMU (Assuming you used the default settings):
```bash
$ runqemu nographic tmp-qemuarm64-glibc/deploy/images/qemuarm64/core-image-minimal-qemuarm64.qemuboot.conf
```
