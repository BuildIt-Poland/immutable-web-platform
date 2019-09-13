#!/usr/bin/env bash
# set -o xtrace
testfiles=$(find . -name run-test.sh)

for f in $testfiles
do
  echo "# Running test for: " $f
	(cd "$(dirname $f)" && ./run-test.sh)
done
