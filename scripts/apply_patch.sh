#!/bin/bash -e

pushd v8
git apply --cached ../9.2.230.18.patch
git checkout -- .
popd
