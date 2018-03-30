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
* cd v8

* Link ndk dir into v8 source path
```
mkdir v8/third_party/android_tools
ln -s $ANDROID_NDK_HOME v8/third_party/android_tools/ndk
```

* checkout tag 6.0.286.52
```
git checkout origin/6.0.286.52
```
* run `gclient sync` (if there are any problems: delete all problematic folders and do `git checkout .`, then run `gclient sync` again, you might need to go to v8/build and undo git changes before calling the glient sync again)
* run command
```
../apply_patch
```

* run the following command in the root folder command
```
./build_v8
```
> you can run: `../build_v8 debug` if you want to build v8 in debug, by default it's built in release.

### Outputs

The output folder is called `dist` and it's created at `v8` root level.



# HOW TO CREATE A NEW PATCH file

git diff 04a2 b36f > patch.diff
