#!/bin/bash

if [ -z "$1" ]
then echo "V8 tag to fetch requried" && exit -1
fi
ndk='19c'

cd ..

# get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) : 
git clone https://chromium.googlesource.com/chromium/tools/ .git
export PATH=`pwd`/depot_tools:$PATH

# make sure you have these packages installed
read -p "Do you want to install neeed apt-get packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then sudo apt-get install curl libc6-dev-i386 g++-multilib libstdc++6-4.8-dev ninja-build
fi


if [ ! -d ndk$ndk ]; then
    # Download Android NDK
    wget https://dl.google.com/android/repository/android-ndk-r$ndk-linux-x86_64.zip
    
    echo "Unzipping ndk. (Log file is unzip.log)"
    # Unzip the Android NDK
    unzip android-ndk-r$ndk-linux-x86_64.zip -d ndk$ndk > "unzip.log"
fi


# Export ANDROID_NDK environment variable
export ANDROID_NDK=`pwd`/ndk$ndk/android-ndk-r$ndk/


# fetch v8 (this will create a `v8` repo folder)
fetch v8

# copy `build_fat` script in `v8` directory
cd v8

# Link ndk dir into v8 source path
mkdir -p third_party/android_tools
ln -fs $ANDROID_NDK third_party/android_tools/ndk


# cp ../android-v8/build_fat build_fat

# list the target tag
git branch --remotes | grep $1

# checkout tag 
git checkout $1

echo "=========================================="
echo
echo "Appling Nativescript Patches. Merge the changes manually (May require fixing build if V8 APIs have changed)"
echo 
echo "=========================================="
git apply --cached ../android-v8/9.2.230.18.patch



