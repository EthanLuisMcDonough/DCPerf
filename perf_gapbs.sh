#!/bin/sh

LLVM_INSTALL=/home/ssm-user/llvm_build/install
GCC_INSTALL=/home/ssm-user/gcc_build/install
ENV_PATH=/home/ssm-user/dcperfenv
DCPERF_ROOT=/home/ssm-user/DCPerfLLVM
SCRIPT_DIR=$( realpath $(dirname -- $0) )

export PATH="$ENV_PATH/bin:$PATH"

TOOLCHAIN=$1
RUN_NAME=$2
if [ -z "$RUN_NAME" ]; then
    RUN_DIR=$SCRIPT_DIR/runs
else
    RUN_DIR=$SCRIPT_DIR/runs/$RUN_NAME
fi

mkdir -p $RUN_DIR

case $TOOLCHAIN in
    clang)
        TARGET=$($LLVM_INSTALL/bin/clang -dumpmachine)
        export LD_LIBRARY_PATH=$LLVM_INSTALL/lib/$TARGET:$LLVM_INSTALL/lib:$LD_LIBRARY_PATH
        ;;
    gcc)
        export LD_LIBRARY_PATH=$GCC_INSTALL/lib64:$LD_LIBRARY_PATH
        ;;
    *)
        echo Invalid toolchain $1
        exit 1
        ;;
esac

RUN_TIMESTAMP=$(date +%s)

TRIAL_NAME=$3
if [ -z "$TRIAL_NAME" ]; then
    TRIAL_NAME="run_${RUN_TIMESTAMP}_${TOOLCHAIN}"
fi

TRIAL_DIR=$RUN_DIR/$TRIAL_NAME
mkdir -p $TRIAL_DIR

GAPBS_ROOT=$DCPERF_ROOT/benchmarks/gapbs
UNDIRECTED=$GAPBS_ROOT/kronecker30_k33U.sg
DIRECTED=$GAPBS_ROOT/kronecker30_k33.sg
WEIGHTED=$GAPBS_ROOT/kronecker30_k33.wsg

for bench in bc bfs cc pr sssp tc; do
    case $bench in
        tc)
	    GRAPH_DIR=$UNDIRECTED
	    ;;
	sssp)
	    GRAPH_DIR=$WEIGHTED
	    ;;
	*)
	    GRAPH_DIR=$DIRECTED
	    ;;
    esac

    if [ ! -f "$GRAPH_DIR" ]; then
	echo "No $GRAPH_DIR, skipping $bench"
        continue
    fi

    BENCH_DIR=$TRIAL_DIR/$bench
    mkdir -p $BENCH_DIR

    TOP_FILE=$BENCH_DIR/perf_top.log
    ANN_FILE=$BENCH_DIR/perf_anno.log
    LOG_FILE=$BENCH_DIR/run_cmd.log
    PERF_FILE="perf_${bench}.data"

    echo "Running $bench"
    perf record --all-user -o $PERF_FILE -- "$GAPBS_ROOT/$bench" -n 10 -f $GRAPH_DIR 2>&1 | tee $LOG_FILE
    perf report --stdio -i $PERF_FILE > $TOP_FILE
    perf annotate -i $PERF_FILE --stdio2 > $ANN_FILE
    rm $PERF_FILE
done
