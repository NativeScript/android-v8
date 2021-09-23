#!/bin/bash -e

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
  case ${opt} in
    r)
      GCLIENT_SYNC_ARGS+=" --revision ${OPTARG}"
      ;;
    s)
      GCLIENT_SYNC_ARGS+=" --no-history"
      ;;
  esac
done
shift $(expr ${OPTIND} - 1)

source $(dirname $0)/env.sh
GCLIENT_SYNC_ARGS+=" --revision $V8_VERSION"

function verify_platform()
{
  local arg=$1
  SUPPORTED_PLATFORMS=(android ios)
  local valid_platform=
  for platform in ${SUPPORTED_PLATFORMS[@]}
  do
    if [[ ${arg} = ${platform} ]]; then
      valid_platform=${platform}
    fi
  done
  if [[ -z ${valid_platform} ]]; then
    echo "Invalid platfrom: ${arg}" >&2
    exit 1
  fi
  echo ${valid_platform}
}
PLATFORM=$(verify_platform $1)

# Install NDK
function installNDK() {
  pushd .
  cd "${V8_DIR}"
  wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip
  unzip -q android-ndk-${NDK_VERSION}-linux-x86_64.zip
  rm -f android-ndk-${NDK_VERSION}-linux-x86_64.zip
  popd
  ls -d ${V8_DIR}
}

if [[ ! -d "${DEPOT_TOOLS_DIR}" || ! -f "${DEPOT_TOOLS_DIR}/gclient" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"

if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
  gclient sync ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "ios" ]]; then
  gclient sync --deps=ios ${GCLIENT_SYNC_ARGS}

  cd "${V8_DIR}/src/tools/clang/dsymutil"
  curl -O http://commondatastorage.googleapis.com/chromium-browser-clang-staging/Mac/dsymutil-354873-1.tgz
  tar -zxvf dsymutil-354873-1.tgz
  # Apply N Patches
  patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/ios/main.patch"
  exit 0
fi

if [[ ${PLATFORM} = "android" ]]; then
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}

  # Patch build-deps installer for snapd not available in docker
  patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  sudo bash -c 'v8/build/install-build-deps-android.sh'

  # Reset changes after installation
  patch -d "${V8_DIR}" -p1 -R < "${PATCHES_DIR}/prebuild_no_snapd.patch"

  # Workaround to install missing sysroot
  gclient sync

  # Workaround to install missing android_sdk tools
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}

  # Apply N Patches
  patch -d "${V8_DIR}" -p1 < "${PATCHES_DIR}/android/main.patch"

  installNDK
  exit 0
fi
