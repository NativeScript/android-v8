# android-v8
Contains the Google's V8 build used in android runtime. The latest branch is [v4.5.103.30](https://github.com/NativeScript/android-v8/tree/v4.5.103.30)

### How to build (linux)

* get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) : 
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
```
* make sure you have these packages installed
```
sudo apt-get install curl libc6-dev-i386 g++-multilib
```

* Download Android NDK 
```
wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
```

* Unzip the Android NDK
```
unzip android-ndk-r12b-linux-x86_64.zip -d ndk12b
```

* Export ANDROID_NDK environment variable
```
export ANDROID_NDK=`pwd`/../ndk12b/android-ndk-r12b/
```

* Link ndk dir into v8 source path
```
mkdir third_party/android_tools
ln -s $ANDROID_NDK third_party/android_tools/ndk
```

* fetch v8 (this will create a `v8` repo folder)
* paste `build_fat` file in `v8` root dir
* cd v8
* list all branches
```
git branch -r
```
* navigate to the chosen git branch 
```
git checkout origin/x.x.xx
```
* run command
```
./build_fat
```

### Outputs

The build will generate three architectures `arm`, `arm64`, `x86`. The output folder is called `dist` and it's created at `v8` root level.
