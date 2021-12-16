#!/bin/bash -e

pushd v8
pushd build
git apply --cached ../../patches/android/build.patch
git checkout -- .
popd
git apply --cached ../patches/android/main.patch
git checkout -- .
popd
