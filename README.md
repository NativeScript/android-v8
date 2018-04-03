# android-v8
Contains the Google's V8 build used in android runtime. The latest branch is [v6.5.254.28](https://github.com/NativeScript/android-v8/tree/trifonov/6.5.254.28)

### How to build (linux)

* get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) :
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
```

* `fetch v8` (this will create a `v8` repo folder)
* cd v8

* checkout tag 6.5.254.28
```
git checkout origin/6.5.254.28
```

* Make sure you have these packages installed (Linux only)
```
sudo apt-get install curl libc6-dev-i386 g++-multilib
```

* Get needed tools and sync (Linux) (if there are any problems with gclient sync: delete all problematic folders and do `git checkout .`, then run `gclient sync` again, you might need to go to v8/build and undo git changes before calling the glient sync again)
```
v8$ echo "target_os = ['android', 'linux']" >> ../.gclient && gclient sync --nohooks
```

* Get needed tools and sync (Mac OS)
```
v8$ echo "target_os = ['android', 'mac']" >> ../.gclient && gclient sync --nohooks
```

* Apply patch running the following command
```
../apply_patch
```

* Export ANDROID_NDK_HOME environment variable
```
export ANDROID_NDK_HOME=/third_party/android_ndk
```

* run the following command in the root folder command
```
./build_v8
```
> you can run: `../build_v8 debug` if you want to build v8 in debug, by default it's built in release. (You minght not be able to build in debug mode on Mac as there are some missing dependencies in the third_party folder)

### Outputs

The output folder is called `dist` and it's created at `v8` root level.



# HOW TO CREATE A NEW PATCH file

git diff 04a2 b36f > patch.diff
