#!/bin/bash -e

pushd v8
git apply --cached ../patches/android/main.patch
git checkout -- .
popd
