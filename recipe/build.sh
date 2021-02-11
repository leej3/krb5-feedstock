#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./src/config
set -xe

export CPPFLAGS="${CPPFLAGS/-DNDEBUG/}"

# https://github.com/conda-forge/bison-feedstock/issues/7
export M4="${BUILD_PREFIX}/bin/m4"

if [[ "$target_platform" == "osx-arm64" ]]; then
    # This can't be deduced when cross-compiling
    export krb5_cv_attr_constructor_destructor=yes,yes
    export ac_cv_func_regcomp=yes
    export ac_cv_printf_positional=yes
    sed -i.bak "s@mig -header@mig -cc $(which $CC) -arch arm64 -header@g" src/lib/krb5/ccache/Makefile.in
fi

if [[ $BOOTSTRAPPING == yes ]]; then
    export TK_OPT="--without-tcl"
else
    export TK_OPT="--with-tcl=${PREFIX}"
fi

pushd src
  autoreconf -i
  ./configure --prefix=${PREFIX}          \
              --host=${HOST}              \
              --build=${BUILD}            \
              $TK_OPT                     \
              --without-readline          \
              --with-libedit              \
              --with-crypto-impl=openssl  \
              --without-system-verto

  make -j${CPU_COUNT} ${VERBOSE_AT}
  make install
popd
