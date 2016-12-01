# android-v8
Contains the Google's V8 build used in android runtime. The latest branch is [v4.5.103.30](https://github.com/NativeScript/android-v8/tree/v4.5.103.30)

### How to build (linux)

* get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) : 
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
```
* make sure you have these packages installed (Ubuntu)
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
export ANDROID_NDK=`pwd`/ndk12b/android-ndk-r12b/
```

* fetch v8 (this will create a `v8` repo folder)

* Link ndk dir into v8 source path
```
mkdir third_party/android_tools
ln -s $ANDROID_NDK v8/third_party/android_tools/ndk
```
* `cd v8`
* checkout branch heads
```
git checkout branch-heads/5.4
git checkout -b <local_branch_name>
```
* run `gclient sync` (if there are any problems: delete all problematic folders and do `git checkout .`, then run `gclient sync` again)
* run script to apply ns patch
```
../apply_patch
```
* build v8 (it might take a while)
```
../build_v8
```

### Outputs

The output folder is called `dist` and it's created at `v8` root level.


# HOW TO CREATE A NEW PATCH file

`git format-patch <SHA/commit> > patch.diff`

# How to apply a patch

`git am <path_to_patch_file>
