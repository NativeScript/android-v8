# android-v8
Contains the Google's V8 build used in android runtime. The latest branch is [v4.5.103.30](https://github.com/NativeScript/android-v8/tree/v4.5.103.30)

### How to build (linux)

* [set up](https://www.chromium.org/developers/how-tos/install-depot-tools) depot_tools: 
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:"$PATH"
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