#Prerequisite

Please read [How to Download and Build V8](https://developers.google.com/v8/build?hl=en)

#Build steps

We build V8 engine on Linux. Our choice of distro is `ubuntu 14.04 LTS, 64-bit`.

>Note: The following build steps are subject of change.

1. `cd v8`
2. Build for ARM architecture `make android_arm.release -j2 i18nsupport=off`
3. Build for x86 architectute `make android_ia32.release -j2 i18nsupport=off`

The output directory is `out`. The output from step 2 is located in `out/android_arm.release` directory. The output from step 3 is located in `out/android_ia32.release` directory.

>Note: By default, V8 build scripts produce static libraries in `thin` format. For a better convenience we repack the libraries in `fat` format using `ar` tool.