# meta-freertos
FreeRTOS distro layer compatible with OpenEmbedded

## Build Status

| master  | [![Build Status][masterbadge]][masterpipeline]   |
|:-------:|--------------------------------------------------|
| kirkstone | [![Build Status][kirkstonebadge]][kirkstonepipeline] |
| dunfell | [![Build Status][dunfellbadge]][dunfellpipeline] |


[masterbadge]: https://dev.azure.com/ahcbb6/meta-freertos/_apis/build/status/FreeRTOS?branchName=master
[masterpipeline]: https://dev.azure.com/ahcbb6/meta-freertos/_build/latest?definitionId=32&branchName=master
[kirkstonebadge]: https://dev.azure.com/ahcbb6/meta-freertos/_apis/build/status/FreeRTOS?branchName=kirkstone
[kirkstonepipeline]: https://dev.azure.com/ahcbb6/meta-freertos/_build/latest?definitionId=32&branchName=kirkstone
[dunfellbadge]: https://dev.azure.com/ahcbb6/meta-freertos/_apis/build/status/FreeRTOS?branchName=dunfell
[dunfellpipeline]: https://dev.azure.com/ahcbb6/meta-freertos/_build/latest?definitionId=32&branchName=dunfell


## Dependencies

This layer depends on:

     URI: git://git.yoctoproject.org/poky
     branch: master


## License
This layer has an MIT license (see LICENSE) and it fetches code from FreeRTOS that has its own License
(MIT as of the day of writing this README), along with code taken from [jkovacic](https://github.com/jkovacic/FreeRTOS-GCC-ARM926ejs) which also has its own license.


## FreeRTOS build setup

1.- Clone the required repositories (Use -b kirkstone if you want a stable release)
```bash
$ git clone https://git.yoctoproject.org/git/poky
$ cd poky
$ git clone https://github.com/ahcbb6/meta-freertos.git
```
2.- Add meta-freertos to your bblayers.conf
```bash
$ source oe-init-build-env
$ bitbake-layers add-layer ../meta-freertos
```
3.- Add the required variables to your local.conf
```bash
$ echo "MACHINE = \"qemuarmv5\"" >> ./conf/local.conf
$ echo "DISTRO = \"freertos\"" >> ./conf/local.conf
```

## Build a FreeRTOS demo as a standalone application:
4.- Build a sample FreeRTOS standalone application:
```bash
$ bitbake freertos-demo
```
5.- Run the application on QEMU:
```bash
$ runqemu nographic
```

After running runqemu you should be able to see the output of the application on QEMU and interact with it.

Sample output:
```bash
###### - FreeRTOS sample application -######

A text may be entered using a keyboard.
It will be displayed when 'Enter' is pressed.

Periodic task 10 secs
Waiting For Notification - Blocked...
Task1
Task1
You entered: "HelloFreeRTOS"
Unblocked
Notification Received
Waiting For Notification - Blocked...
```


## Build Linux along with FreeRTOS (Linux on qemux86-64 and FreeRTOS on qemuarmv5):
(First 3 steps still apply)

4.- Enable multiconfig builds on your local.conf
```bash
$ echo "BBMULTICONFIG = \"dummy-x86-64\"" >> ./conf/local.conf
```
5.- Create a multiconfig dependency so freertos gets built automatically when building Linux
```bash
$ echo "do_image[mcdepends] = \"multiconfig:dummy-x86-64::freertos-demo-local:do_image\"" >> ./conf/local.conf
```
6.- Build Linux image and get a FreeRTOS demo for free!
```bash
$ bitbake mc:dummy-x86-64:core-image-minimal
```
7.- Run the FreeRTOS application on QEMU:
```bash
$ runqemu nographic
```
8.- Run the Linux image on QEMU (Assuming you used the default settings):
```bash
$ runqemu nographic tmp-qemux86-64-glibc/deploy/images/qemux86-64/core-image-minimal-qemux86-64.qemuboot.conf
```
