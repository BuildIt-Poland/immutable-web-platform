#!/usr/bin/env bash
set -o xtrace
cd $(dirname $0)
testfiles=$(find . -name test.nix)
nix-build -E "with import ./. {}; nix-test { testFiles = [ $testfiles ]; }" --show-trace && cat result
