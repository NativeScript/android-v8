#!/bin/bash

pushd v8
git apply --cached ../7.3.492.25.patch
git checkout -- .
popd

pushd v8/build
git apply --cached ../../build.patch
git checkout -- .
popd

