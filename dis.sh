#!/bin/sh

SCRIPT_PATH=$(realpath $(dirname -- $0))
ABIN=$SCRIPT_PATH/assembly_dumps

mkdir -p $ABIN

for compiler in clang gcc; do
    for opt in Default Release; do
	$SCRIPT_PATH/build_gapbs.sh $compiler $opt
        for bench in bc bfs cc pr sssp tc; do
	    objdump -d $SCRIPT_PATH/benchmarks/gapbs/$bench > $ABIN/$bench-$compiler-$opt.S
	done
    done
done

