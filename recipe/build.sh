#!/bin/bash
# Get an updated config.sub and config.guess
if [[ ! $BOOTSTRAPPING == yes ]]; then
  cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./src/config
  # https://github.com/conda-forge/bison-feedstock/issues/7
  export M4="${BUILD_PREFIX}/bin/m4"
fi

set -xe

export CPPFLAGS="${CPPFLAGS/-DNDEBUG/}"

if [[ "$target_platform" == "osx-arm64" ]]; then
    # This can't be deduced when cross-compiling
    export krb5_cv_attr_constructor_destructor=yes,yes
    export ac_cv_func_regcomp=yes
    export ac_cv_printf_positional=yes
    sed -i.bak "s@mig -header@mig -cc $(which $CC) -arch arm64 -header@g" src/lib/krb5/ccache/Makefile.in
fi

if [[ $BOOTSTRAPPING == yes ]]; then
    export OPTS="--without-tcl --without-libedit"
else
    export TCL_OPT="--with-tcl=${PREFIX} --with-libedit"
fi

pushd src
  autoreconf -i
  ./configure --prefix=${PREFIX}          \
              --host=${HOST}              \
              --build=${BUILD}            \
              $OPTS                       \
              --without-readline          \
              --with-crypto-impl=openssl  \
              --without-system-verto

  make -j${CPU_COUNT} ${VERBOSE_AT}
  make install
popd
