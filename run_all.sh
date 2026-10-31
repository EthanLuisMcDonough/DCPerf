#!/bin/sh

SCRIPT_DIR=$( realpath $(dirname -- $0) )
#OUT_DIR=$(realpath $1)
OUT_DIR=$1
#mkdir -p $OUT_DIR

cd $SCRIPT_DIR

set -e
for toolchain in gcc clang; do
   for mode in Default Release; do
       echo STARTING $mode $toolchain
       $SCRIPT_DIR/build_gapbs.sh $toolchain $mode runs/$OUT_DIR
       $SCRIPT_DIR/run_gapbs.sh $toolchain $OUT_DIR $toolchain-$mode
   done
done
