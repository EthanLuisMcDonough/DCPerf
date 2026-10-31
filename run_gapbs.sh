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

BENCHMARKS=()

if [ -f $DCPERF_ROOT/benchmarks/gapbs/*U.sg ]; then
    BENCHMARKS+=(tc)
elif [ -f $DCPERF_ROOT/benchmarks/gapbs/*.sg ]; then
    BENCHMARKS+=(bc bfs cc pr)
fi

if [ -f $DCPERF_ROOT/benchmarks/gapbs/*.wsg ]; then
    BENCHMARKS+=(sssp)
fi

for bench in "${BENCHMARKS[@]}"; do
    BENCH_DIR=$TRIAL_DIR/$bench
    mkdir -p $BENCH_DIR

    RESULTS_DIR=$BENCH_DIR/results
    ARTIFACTS_DIR=$BENCH_DIR/artifacts
    LOG_FILE=$BENCH_DIR/run_cmd.log

    mkdir -p $RESULTS_DIR
    mkdir -p $ARTIFACTS_DIR

    echo $bench
    python3 $DCPERF_ROOT/benchpress_cli.py -b mem --results $RESULTS_DIR \
        --artifacts-dir $ARTIFACTS_DIR -t $RUN_TIMESTAMP run gapbs_multi \
        -i "{\"num_instances\": 1, \"trials\": 10, \"bench\": \"$bench\"}" 2>&1 | tee $LOG_FILE
done
