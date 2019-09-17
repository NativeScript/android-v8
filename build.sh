#!/bin/bash

## prepare configuration

IS_COMPONENT_BUILD=true
IS_LINUX=false
SNAPSHOT_PREFIX=""

case "$(uname -s)" in

   Darwin)
     echo 'Mac OS X'
         IS_COMPONENT_BUILD=false
         cp ./llvm-ar ./v8/third_party/llvm-build/Release+Asserts/bin
         NDK_BUILD_TOOLS_ARR=(
                $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/arm-linux-androideabi/bin \
                $ANDROID_NDK_HOME/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/aarch64-linux-android/bin \
                $ANDROID_NDK_HOME/toolchains/x86-4.9/prebuilt/darwin-x86_64/i686-linux-android/bin \
                $ANDROID_NDK_HOME/toolchains/x86_64-4.9/prebuilt/darwin-x86_64/x86_64-linux-android/bin
        )
     ;;

   Linux)
     echo 'Linux'
         IS_LINUX=true
         SNAPSHOT_PREFIX="snapshot-"
         NDK_BUILD_TOOLS_ARR=($ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin \
                $ANDROID_NDK_HOME/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/aarch64-linux-android/bin \
                $ANDROID_NDK_HOME/toolchains/x86-4.9/prebuilt/linux-x86_64/i686-linux-android/bin \
                $ANDROID_NDK_HOME/toolchains/x86_64-4.9/prebuilt/linux-x86_64/x86_64-linux-android/bin)
     ;;

   *)
     echo 'Unsupported OS'
     ;;
esac

# The order of CPU architectures in this array must be the same
# as the order of NDK tools in the NDK_BUILD_TOOLS_ARR array
ARCH_ARR=(arm arm64 x86 x64)

BUILD_DIR_PREFIX="outgn"

BUILD_TYPE="release"

cd v8
if [[ $1 == "debug" ]] ;then
        BUILD_TYPE="debug"
fi
# generate project in release mode
for CURRENT_ARCH in ${ARCH_ARR[@]}
do
        ARGS=
        if [[ $BUILD_TYPE == "debug" ]] ;then
                if $IS_LINUX; then
                    gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=$IS_COMPONENT_BUILD v8_use_snapshot=true v8_use_external_startup_data=true v8_enable_embedded_builtins=true is_debug=true symbol_level=2 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
                fi
                gn gen $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=false v8_use_snapshot=true v8_use_external_startup_data=true v8_enable_embedded_builtins=true is_debug=true symbol_level=2 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
        else
                if $IS_LINUX; then
                    gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=$IS_COMPONENT_BUILD v8_use_snapshot=true v8_use_external_startup_data=true v8_enable_embedded_builtins=true is_official_build=true use_thin_lto=false is_debug=false symbol_level=0 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
                fi
                gn gen $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=false v8_use_snapshot=true v8_use_external_startup_data=true v8_enable_embedded_builtins=true is_official_build=true use_thin_lto=false is_debug=false symbol_level=0 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"

        fi
done

# compile project
COUNT=0
for CURRENT_ARCH in ${ARCH_ARR[@]}
do
        # make fat build
        V8_FOLDERS=(v8_compiler v8_base_without_compiler v8_libplatform v8_libbase v8_libsampler v8_external_snapshot v8_initializers v8_init torque_generated_initializers)

        SECONDS=0
        if $IS_LINUX; then
            ninja -C $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE ${V8_FOLDERS[@]} inspector
        fi
        ninja -C $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE run_mksnapshot_default

        echo "build finished in $SECONDS seconds"

        DIST="./dist/"
        mkdir -p $DIST/$CURRENT_ARCH-$BUILD_TYPE

        if $IS_LINUX; then
            CURRENT_BUILD_TOOL=${NDK_BUILD_TOOLS_ARR[$COUNT]}
            COUNT=$COUNT+1
            V8_FOLDERS_LEN=${#V8_FOLDERS[@]}
            LAST_PARAM=""
            for CURRENT_V8_FOLDER in ${V8_FOLDERS[@]}
            do
                LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/${CURRENT_V8_FOLDER}/*.o"
            done

            THIRD_PARTY_OUT=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/obj/buildtools/third_party
            LAST_PARAM="${LAST_PARAM} $THIRD_PARTY_OUT/libc++/libc++/*.o $THIRD_PARTY_OUT/libc++abi/libc++abi/*.o"

            eval $CURRENT_BUILD_TOOL/ar r $DIST/$CURRENT_ARCH-$BUILD_TYPE/libv8.a "${LAST_PARAM}"
        fi

        echo "=================================="
        echo "=================================="
        echo "Copying snapshot binaries for $CURRENT_ARCH"
        echo "=================================="
        echo "=================================="
        DIST="./dist/snapshots/$CURRENT_ARCH-$BUILD_TYPE/"
        mkdir -p $DIST

        SOURCE_DIR=
        if [[ $CURRENT_ARCH == "arm64" ]] ;then
                SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x64_v8_$CURRENT_ARCH
        elif [[ $CURRENT_ARCH == "arm" ]] ;then
                SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x86_v8_$CURRENT_ARCH
        elif [[ $CURRENT_ARCH == "x86" ]] ;then
                SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x86
        elif [[ $CURRENT_ARCH == "x64" ]] ;then
                SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x64
        fi

        cp -r $SOURCE_DIR/mksnapshot $DIST

        if $IS_LINUX; then
            echo "=================================="
            echo "=================================="
            echo "Preparing snapshot headers for $CURRENT_ARCH"
            echo "=================================="
            echo "=================================="

            INCLUDE="$(pwd)/dist/$CURRENT_ARCH-$BUILD_TYPE/include"
            mkdir -p $INCLUDE

            SOURCE_DIR=
            if [[ $CURRENT_ARCH == "arm64" ]] ;then
                    SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x64_v8_$CURRENT_ARCH
            elif [[ $CURRENT_ARCH == "arm" ]] ;then
                    SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x86_v8_$CURRENT_ARCH
            elif [[ $CURRENT_ARCH == "x86" ]] ;then
                    SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x86
            elif [[ $CURRENT_ARCH == "x64" ]] ;then
                    SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x64
            fi

            pushd $SOURCE_DIR/..
            xxd -i snapshot_blob.bin > $INCLUDE/snapshot_blob.h
            xxd -i natives_blob.bin > $INCLUDE/natives_blob.h
            popd
        fi
done
