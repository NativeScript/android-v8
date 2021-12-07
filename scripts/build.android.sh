#!/bin/bash -e

source $(dirname $0)/env.sh

ARCH_ARR=(arm arm64 x86 x64)
while getopts 'l:' opt; do
  case ${opt} in
    l)
        ARCH_ARR=($OPTARG)
      ;;
  esac
done
shift $(expr ${OPTIND} - 1)
## prepare configuration

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

BUILD_DIR_PREFIX="outgn"

BUILD_TYPE="release"

cd ${V8_DIR}
if [[ $1 == "debug" ]] ;then
        BUILD_TYPE="debug"
fi
# generate project in release mode
for CURRENT_ARCH in ${ARCH_ARR[@]}
do
        if [[ $BUILD_TYPE == "debug" ]] ;then
                gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="is_component_build=true v8_use_external_startup_data=true is_debug=true symbol_level=2 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false"
        else
                ARGS="use_goma=false is_clang=true enable_resource_allowlist_generation=false is_component_build=true v8_use_external_startup_data=false is_official_build=true use_thin_lto=false is_debug=false symbol_level=0 target_cpu=\"$CURRENT_ARCH\" v8_target_cpu=\"$CURRENT_ARCH\" v8_enable_i18n_support=false target_os=\"android\" v8_android_log_stdout=false use_custom_libcxx=true cc_wrapper=\"ccache\""
                if [[ $CURRENT_ARCH =~ 64$ ]] ;then
                        gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="$ARGS"
                else
                        gn gen $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE --args="$ARGS android32_ndk_api_level=$NDK_API_LEVEL android_ndk_major_version=$NDK_API_LEVEL android_sdk_platform_version=$NDK_API_LEVEL android_sdk_version=$NDK_API_LEVEL android64_ndk_api_level=$NDK_API_LEVEL"
                fi

        fi
done

# compile project
COUNT=0
for CURRENT_ARCH in ${ARCH_ARR[@]}
do

        # make fat build
        V8_FOLDERS=(v8_compiler v8_base_without_compiler v8_libplatform v8_snapshot v8_libbase v8_bigint torque_generated_initializers torque_generated_definitions)
        export CCACHE_CPP2=yes
	export CCACHE_SLOPPINESS=time_macros
	export PATH=$V8_DIR/third_party/llvm-build/Release+Asserts/bin:$PATH
        SECONDS=0
        ninja -C $BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE ${V8_FOLDERS[@]} inspector

        echo "build finished in $SECONDS seconds"

        mkdir -p $DIST_DIR/$CURRENT_ARCH-$BUILD_TYPE

        OUTFOLDER=${BUILD_DIR_PREFIX}/${CURRENT_ARCH}-${BUILD_TYPE}
        CURRENT_BUILD_TOOL=${NDK_BUILD_TOOLS_ARR[$COUNT]}
        COUNT=$COUNT+1
        V8_FOLDERS_LEN=${#V8_FOLDERS[@]}
        LAST_PARAM=""
        for CURRENT_V8_FOLDER in ${V8_FOLDERS[@]}
        do
        LAST_PARAM="${LAST_PARAM} ${OUTFOLDER}/obj/${CURRENT_V8_FOLDER}/*.o"
        done

        $CURRENT_BUILD_TOOL/ar r $OUTFOLDER/obj/third_party/inspector_protocol/libinspector_protocol.a $OUTFOLDER/obj/third_party/inspector_protocol/crdtp/*.o $OUTFOLDER/obj/third_party/inspector_protocol/crdtp_platform/*.o
        cp "$OUTFOLDER/obj/third_party/inspector_protocol/libinspector_protocol.a" "$DIST_DIR/${CURRENT_ARCH}${DIST_SUFFIX}"

        LAST_PARAM="${LAST_PARAM} $OUTFOLDER/obj/third_party/zlib/zlib/*.o ${OUTFOLDER}/obj/third_party/zlib/zlib/*.o ${OUTFOLDER}/obj/third_party/zlib/zlib_adler32_simd/*.o ${OUTFOLDER}/obj/third_party/zlib/google/compression_utils_portable/*.o ${OUTFOLDER}/obj/third_party/zlib/zlib_inflate_chunk_simd/*.o"

        LAST_PARAM="${LAST_PARAM} ${OUTFOLDER}/obj/third_party/android_ndk/cpu_features/*.o"
        LAST_PARAM="${LAST_PARAM} ${OUTFOLDER}/obj/cppgc_base/*.o ${OUTFOLDER}/obj/v8_cppgc_shared/*.o"
        
        
        if [[ $CURRENT_ARCH = "arm" || $CURRENT_ARCH = "arm64" ]]; then
                LAST_PARAM="${LAST_PARAM} ${OUTFOLDER}/obj/third_party/zlib/zlib_arm_crc32/*.o"
        fi

        if [[ $CURRENT_ARCH = "x86" || $CURRENT_ARCH = "x64" ]]; then
                LAST_PARAM="${LAST_PARAM} ${OUTFOLDER}/obj/third_party/zlib/zlib_x86_simd/*.o ${OUTFOLDER}/obj/third_party/zlib/zlib_crc32_simd/*.o"
        fi

        THIRD_PARTY_OUT=$BUILD_DIR_PREFIX/$CURRENT_ARCH-$BUILD_TYPE/obj/buildtools/third_party
        LAST_PARAM="${LAST_PARAM} $THIRD_PARTY_OUT/libc++/libc++/*.o $THIRD_PARTY_OUT/libc++abi/libc++abi/*.o"
        
        $CURRENT_BUILD_TOOL/ar r $DIST_DIR/$CURRENT_ARCH-$BUILD_TYPE/libv8.a ${LAST_PARAM}
done
