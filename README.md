# android-v8
Contains the Google's V8 build used in android runtime.

### How to build (linux)

* get depot tools [more](https://www.chromium.org/developers/how-tos/install-depot-tools) :
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
```

* Make sure you have these packages installed (Linux only)
```
sudo apt-get install curl libc6-dev-i386 g++-multilib
```

* Download and extract Android NDK 16b

Mac OS:
```
curl -O https://dl.google.com/android/repository/android-ndk-r17b-darwin-x86_64.zip
unzip android-ndk-r17b-darwin-x86_64.zip -d ndkr17b
```

Linux:
```
curl -O https://dl.google.com/android/repository/android-ndk-r17b-linux-x86_64.zip
unzip android-ndk-r17b-linux-x86_64.zip -d ndkr17b
```

* Export ANDROID_NDK_HOME environment variable
```
export ANDROID_NDK_HOME=`pwd`/ndkr17b/android-ndk-r17b
```

* `fetch v8` (this will create a `v8` repo folder)
* cd v8

* Create symlinks
```
mkdir third_party/android_tools
ln -s $ANDROID_NDK_HOME third_party/android_tools/ndk
ln -s $ANDROID_NDK_HOME third_party/android_ndk
```

* checkout tag 6.7.288.46
```
git checkout 6.7.288.46
```

* Run sync
```
gclient sync
```

* Apply patch running the following command
```
../apply_patch
```

* run the following command in the root folder command
```
../build_v8
```
> you can run: `../build_v8 debug` if you want to build v8 in debug, by default it's built in release.

### Outputs

The output folder is called `dist` and it's created at `v8` root level.

### HOW TO CREATE A NEW PATCH file

git diff 04a2 b36f > patch.diff

### What to do next

* Copy the files from the **v8/dist** folder in the corresponding folder in [android-runtime](https://github.com/NativeScript/android-runtime/tree/master/test-app/runtime/src/main/libs)
* Update the **v8-versions.json** file in the [android-runtime root folder](https://github.com/NativeScript/android-runtime/blob/master/v8-versions.json)
* Update the **settings.json** file in [android-runtime/build-artifacts/project-template-gradle](https://github.com/NativeScript/android-runtime/tree/master/build-artifacts/project-template-gradle/settings.json)
* Replace all the needed header and inspector files in the repo. The following [article](https://github.com/NativeScript/android-runtime/blob/master/docs/extending-inspector.md) might be helpful 
