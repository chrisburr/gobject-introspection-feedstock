#! /bin/bash

set -e
IFS=$' \t\n' # workaround for conda 4.2.13+toolchain bug

export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig

configure_args=(
    --prefix=$PREFIX
    --disable-dependency-tracking
    --with-cairo
)

if [ $PY3K = 1 ] ; then
    # Work around a weakness in AM_CHECK_PYTHON_HEADERS. It finds the name of
    # $PYTHON, then runs "$PYTHON-config" to get the header locations. On
    # Unixy platforms, conda-build sets $PYTHON to "$PREFIX/bin/python", so
    # the configure script adopts that value. But in Python 3 situations,
    # Anaconda does not "$PREFIX/bin/python-config", so the header check
    # fails. Anaconda does provide "python3-config", though, so if we just
    # tweak the executable name, we work.
    configure_args+=(--with-python=python3)
fi

if [ $(uname) = Darwin ] ; then
    LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

./configure "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make -j$CPU_COUNT
make install

if [ -z "$OSX_ARCH" ] ; then
    make check
else
    # Test suite does not fully work on OSX, but not because anything is broken.
    make check-local check-TESTS
    (cd tests && make check-TESTS) || exit 1
    (cd tests/offsets && make check) || exit 1
    (cd tests/warn && make check) || exit 1
fi

rm -f $PREFIX/lib/libgirepository-*.a $PREFIX/lib/libgirepository-*.la
