# meta-freertos
FreeRTOS distro layer compatible with OpenEmbedded

## Build Status

|  master 	| [![Build Status](https://dev.azure.com/aehs29/meta-freertos/_apis/build/status/aehs29.meta-freertos?branchName=master)](https://dev.azure.com/aehs29/meta-freertos/_build/latest?definitionId=1&branchName=master)  	|
|:-:	|---	|
| zeus  	|  [![Build Status](https://dev.azure.com/aehs29/meta-freertos/_apis/build/status/aehs29.meta-freertos?branchName=zeus)](https://dev.azure.com/aehs29/meta-freertos/_build/latest?definitionId=1&branchName=zeus) 	|
| warrior  	|  [![Build Status](https://dev.azure.com/aehs29/meta-freertos/_apis/build/status/aehs29.meta-freertos?branchName=warrior)](https://dev.azure.com/aehs29/meta-freertos/_build/latest?definitionId=1&branchName=warrior) 	|

## Dependencies

This layer depends on:

     URI: git://git.yoctoproject.org/poky
     branch: master


## License
This layer has an MIT license (see LICENSE) and it fetches code from FreeRTOS that has its own License
(MIT as of today), along with code taken from [jkovacic](https://github.com/jkovacic/FreeRTOS-GCC-ARM926ejs) which also has its own license.


## Building a FreeRTOS application

1.- Clone the required repositories
```bash
$ git clone https://git.yoctoproject.org/git/poky -b zeus
$ cd poky
$ git clone https://github.com/aehs29/meta-freertos.git -b zeus
```
2.- Add meta-freertos to your bblayers.conf
```bash
$ source oe-init-build-env
$ bitbake-layers add-layer ../meta-freertos
```
3.- Add the required variables to your local.conf
```bash
$ echo "MACHINE = \"qemuarmv5\"" >> ./conf/local.conf
$ echo "DISTRO = \"poky-freertos\"" >> ./conf/local.conf
```
4.- Build a sample FreeRTOS application:
```bash
$ bitbake freertos-demo
```
5.- Run the application on QEMU:
```bash
$ runqemu
```
You should be able to see the output of the application on QEMU and interact with it.
