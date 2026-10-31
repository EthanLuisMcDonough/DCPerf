#!/bin/sh

LLVM_INSTALL=/home/ssm-user/llvm_build/install
GCC_INSTALL=/home/ssm-user/gcc_build/install
ENV_PATH=/home/ssm-user/dcperfenv
DCPERF_ROOT=/home/ssm-user/DCPerfLLVM
SCRIPT_DIR=$( realpath $(dirname -- $0) )

export PATH="$ENV_PATH/bin:$PATH"

TOOLCHAIN=$1
OPT_LEVEL=$2
BUILD_LOG=$3

if [ -z "$3" ]; then
    BUILD_LOGS_DIR=$SCRIPT_DIR/build_logs
else
    BUILD_LOGS_DIR=$3
fi

mkdir -p $BUILD_LOGS_DIR

case $TOOLCHAIN in
    clang)
        export PATH=$LLVM_INSTALL/bin:$PATH
        export CC=$LLVM_INSTALL/bin/clang
        export CXX=$CC++
        TARGET=$($CC -dumpmachine)
        export LIBRARY_PATH=$LLVM_INSTALL/lib/$TARGET:$LLVM_INSTALL/lib:$LIBRARY_PATH
        export LD_LIBRARY_PATH=$LLVM_INSTALL/lib/$TARGET:$LLVM_INSTALL/lib:$LD_LIBRARY_PATH
        ;;
    gcc)
        export PATH=$GCC_INSTALL/bin:$PATH
        export CC=$GCC_INSTALL/bin/gcc
        export CXX=$GCC_INSTALL/bin/g++
        export LIBRARY_PATH=$GCC_INSTALL/lib64:$LIBRARY_PATH
        export LD_LIBRARY_PATH=$GCC_INSTALL/lib64:$LD_LIBRARY_PATH
        ;;
    *)
        echo Invalid toolchain $1
        exit 1
        ;;
esac

OPT_FLAG=""
case $OPT_LEVEL in
    Release)
        OPT_FLAG="-O3"
        ;;
    Default)
        OPT_FLAG="-O2"
        ;;
    Debug)
        OPT_FLAG="-O0"
        ;;
    *)
        echo INVALID OPT LEVEL
        exit 1
        ;;
esac
DEFAULT_FLAGS="-g $OPT_FLAG $TOOLCHAIN_FLAGS"

export CXXFLAGS=$DEFAULT_FLAGS
export CFLAGS=$DEFAULT_FLAGS
BUILD_TIMESTAMP=$(date +%s)
export CXX_FLAGS=$CXXFLAGS

python3 $DCPERF_ROOT/benchpress_cli.py -b mem install -f gapbs_multi 2>&1 | \
    tee "$BUILD_LOGS_DIR/build_gapbs_${BUILD_TIMESTAMP}_${TOOLCHAIN}_${OPT_LEVEL}.log" 
