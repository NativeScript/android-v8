# android-v8
Contains the Google's V8 build used in android runtime. The latest branch is [v4.5.103.30](https://github.com/NativeScript/android-v8/tree/v4.5.103.30)

### How to build (linux or mac)

* get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) :
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
```
* make sure you have these packages installed (Ubuntu)
```
sudo apt-get install curl libc6-dev-i386 g++-multilib
```

* Set Up Android NDK (linux)
```
wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
unzip android-ndk-r12b-linux-x86_64.zip -d ndk12b
```

* Set Up Android NDK (mac)
```
wget https://dl.google.com/android/repository/android-ndk-r12b-darwin-x86_64.zip
unzip android-ndk-r12b-darwin-x86_64.zip -d ndk12b
```

* Export ANDROID_NDK_HOME environment variable
```
export ANDROID_NDK_HOME=`pwd`/ndk12b/android-ndk-r12b/
```

* `fetch v8` (this will create a `v8` repo folder)

* Link ndk dir into v8 source path
```
mkdir v8/third_party/android_tools
ln -s $ANDROID_NDK_HOME v8/third_party/android_tools/ndk
```
* `cd v8`
* checkout branch 5.5.372.32
```
git checkout 5.5.372.32
git checkout -b <local_branch_name>
```
* run `gclient sync` (if there are any problems: delete all problematic folders and do `git checkout .`, then run `gclient sync` again, you might need to go to v8/build and undo git changes before calling the glient sync again)
* run script to apply ns patch
```
../apply_patch
```
* If you are building on mac you'll need to change the v8/build/toolchain/mac adding the following content:
```
mac_toolchain("clang_x86") {
  toolchain_args = {
    current_cpu = "x86"
    current_os = "mac"
  }
}

mac_toolchain("clang_x86_v8_arm") {
  toolchain_args = {
    current_cpu = "x86"
    v8_current_cpu = "arm"
    current_os = "mac"
  }
}

mac_toolchain("clang_x64_v8_arm64") {
  toolchain_args = {
    current_cpu = "x64"
    v8_current_cpu = "arm64"
    current_os = "mac"
  }
}
```
* build v8 from the root folder (it might take a while)
```
./build_v8
```

### Outputs

The output folder is called `dist` and it's created at `v8` root level.


# HOW TO CREATE A NEW PATCH file

`git format-patch <SHA/commit> > patch.diff`

# How to apply a patch

`git am <path_to_patch_file>
