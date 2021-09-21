#!/bin/bash -e

source $(dirname $0)/env.sh
## prepare configuration

SNAPSHOT_PREFIX="snapshot-"

if [ "$(uname)" == "Darwin" ]; then
        NDK_BUILD_TOOLS_ARR=($ANDROID_NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/arm-linux-androideabi/bin \
                $ANDROID_NDK/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/aarch64-linux-android/bin \
                $ANDROID_NDK/toolchains/x86-4.9/prebuilt/darwin-x86_64/i686-linux-android/bin \
                $ANDROID_NDK/toolchains/x86_64-4.9/prebuilt/darwin-x86_64/x86_64-linux-android/bin)
else
        NDK_BUILD_TOOLS_ARR=($ANDROID_NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin \
                $ANDROID_NDK/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/aarch64-linux-android/bin \
                $ANDROID_NDK/toolchains/x86-4.9/prebuilt/linux-x86_64/i686-linux-android/bin \
                $ANDROID_NDK/toolchains/x86_64-4.9/prebuilt/linux-x86_64/x86_64-linux-android/bin)
fi

# The order of CPU architectures in this array must be the same
# as the order of NDK tools in the NDK_BUILD_TOOLS_ARR array
ARCH_ARR=(arm arm64 x86 x64)

BUILD_DIR_PREFIX="outgn"

BUILD_TYPE="release"

cd ${V8_DIR}
if [[ $1 == "debug" ]] ;then
        BUILD_TYPE="debug"
fi
# generate project in release mode
for CURRENT_ARCH in ${ARCH_ARR[@]}
do
        ARGS=
        if [[ $BUILD_TYPE == "debug" ]] ;then
                gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=true v8_use_external_startup_data=true is_debug=true symbol_level=2 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
               # gn gen $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=false v8_use_external_startup_data=true is_debug=true symbol_level=2 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
        else
                gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="is_clang=true enable_resource_allowlist_generation=false is_component_build=true v8_use_external_startup_data=true is_official_build=true use_thin_lto=false is_debug=false symbol_level=0 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false ndk_api=$NDK_API_LEVEL android32_ndk_api_level=$NDK_API_LEVEL android_ndk_major_version=$NDK_API_LEVEL android_sdk_platform_version=$NDK_API_LEVEL android_sdk_version=$NDK_API_LEVEL android64_ndk_api_level=$NDK_API_LEVEL"
               # gn gen $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE --args="enable_resource_allowlist_generation=false is_component_build=false v8_use_external_startup_data=true is_official_build=true use_thin_lto=false is_debug=false symbol_level=0 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"

        fi
done

# compile project
COUNT=0
for CURRENT_ARCH in ${ARCH_ARR[@]}
do

        # make fat build
        V8_FOLDERS=(v8_compiler v8_base_without_compiler v8_libplatform v8_snapshot v8_libbase v8_bigint torque_generated_initializers torque_generated_definitions)

        SECONDS=0
        ninja -C $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE ${V8_FOLDERS[@]} inspector
        #ninja -C $BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE run_mksnapshot_default

        echo "build finished in $SECONDS seconds"

        mkdir -p $DIST_DIR/$CURRENT_ARCH-$BUILD_TYPE

        CURRENT_BUILD_TOOL=${NDK_BUILD_TOOLS_ARR[$COUNT]}
        COUNT=$COUNT+1
        V8_FOLDERS_LEN=${#V8_FOLDERS[@]}
        LAST_PARAM=""
        for CURRENT_V8_FOLDER in ${V8_FOLDERS[@]}
        do
        LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/${CURRENT_V8_FOLDER}/*.o"
        done

        LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/inspector_protocol/crdtp/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/inspector_protocol/crdtp_platform/*.o"
        LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib_adler32_simd/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/google/compression_utils_portable/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib_inflate_chunk_simd/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/android_ndk/cpu_features/*.o"
        
        
        LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/cppgc_base/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/v8_cppgc_shared/*.o"
        
        
        if [[ $CURRENT_ARCH = "arm" || $CURRENT_ARCH = "arm64" ]]; then
                LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib_arm_crc32/*.o"
        fi

        if [[ $CURRENT_ARCH = "x86" || $CURRENT_ARCH = "x64" ]]; then
                LAST_PARAM="${LAST_PARAM} ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib_x86_simd/*.o ${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}/obj/third_party/zlib/zlib_crc32_simd/*.o"
        fi

        THIRD_PARTY_OUT=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/obj/buildtools/third_party
        LAST_PARAM="${LAST_PARAM} $THIRD_PARTY_OUT/libc++/libc++/*.o $THIRD_PARTY_OUT/libc++abi/libc++abi/*.o"

        eval $CURRENT_BUILD_TOOL/ar r $DIST_DIR/$CURRENT_ARCH-$BUILD_TYPE/libv8.a "${LAST_PARAM}"

        # echo "=================================="
        # echo "=================================="
        # echo "Copying snapshot binaries for $CURRENT_ARCH"
        # echo "=================================="
        # echo "=================================="
        # DIST="./dist/snapshots/$CURRENT_ARCH-$BUILD_TYPE/"
        # mkdir -p $DIST

        # SOURCE_DIR=
        # if [[ $CURRENT_ARCH == "arm64" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x64_v8_$CURRENT_ARCH
        # elif [[ $CURRENT_ARCH == "arm" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x86_v8_$CURRENT_ARCH
        # elif [[ $CURRENT_ARCH == "x86" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x86
        # elif [[ $CURRENT_ARCH == "x64" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$SNAPSHOT_PREFIX$CURRENT_ARCH-$BUILD_TYPE/clang_x64
        # fi

        # cp -r $SOURCE_DIR/mksnapshot $DIST

        # echo "=================================="
        # echo "=================================="
        # echo "Preparing snapshot headers for $CURRENT_ARCH"
        # echo "=================================="
        # echo "=================================="

        # INCLUDE="$(pwd)/dist/$CURRENT_ARCH-$BUILD_TYPE/include"
        # mkdir -p $INCLUDE

        # SOURCE_DIR=
        # if [[ $CURRENT_ARCH == "arm64" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x64_v8_$CURRENT_ARCH
        # elif [[ $CURRENT_ARCH == "arm" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x86_v8_$CURRENT_ARCH
        # elif [[ $CURRENT_ARCH == "x86" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x86
        # elif [[ $CURRENT_ARCH == "x64" ]] ;then
        #         SOURCE_DIR=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/clang_x64
        # fi

        # pushd $SOURCE_DIR/..
        # xxd -i snapshot_blob.bin > $INCLUDE/snapshot_blob.h
        # popd
done
