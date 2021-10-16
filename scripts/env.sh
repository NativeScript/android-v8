#!/bin/bash -e

CURR_DIR=$(dirname $(realpath $0))
ROOT_DIR=$(dirname ${CURR_DIR})
unset CURR_DIR

DEPOT_TOOLS_DIR="${ROOT_DIR}/scripts/depot_tools"
V8_DIR="${ROOT_DIR}/v8"
DIST_DIR="${ROOT_DIR}/dist"
PATCHES_DIR="${ROOT_DIR}/patches"

V8_VERSION="9.3.345.19"
NDK_VERSION="r22"
NDK_API_LEVEL="19"
IOS_DEPLOYMENT_TARGET="9"

ANDROID_NDK="${V8_DIR}/android-ndk-${NDK_VERSION}"

export PATH="$DEPOT_TOOLS_DIR:$PATH"
