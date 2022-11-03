#!/bin/bash

set -e
set -x

BASE=`pwd`
SRC=$BASE/src
PATCHES=$BASE/patches
RPATH=$PREFIX/lib
DEST=$BASE$PREFIX
LDFLAGS="-L$DEST/lib -s -Wl,--dynamic-linker=$PREFIX/lib/ld-musl-aarch64.so.1 -Wl,-rpath,$RPATH -Wl,-rpath-link,$DEST/lib"
CPPFLAGS="-I$DEST/include"
CFLAGS=$EXTRACFLAGS
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=$PREFIX --host=$DESTARCH-linux"
MAKE="make -j`nproc`"
export CCACHE_DIR=$HOME/.ccache_rust

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

OPENSSL_VERSION=1.1.1s

cd $SRC/openssl

if [ ! -f .extracted ]; then
	rm -rf openssl openssl-${OPENSSL_VERSION}
	tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
	mv openssl-${OPENSSL_VERSION} openssl
	touch .extracted
fi

cd openssl

if [ ! -f .configured ]; then
	./Configure linux-aarch64 \
	$LDFLAGS $CFLAGS \
	--prefix=$PREFIX
	touch .configured
fi

if [ ! -f .built ]; then
	make CC=$DESTARCH-linux-gcc
	touch .built
fi

if [ ! -f .installed ]; then
	make install CC=$DESTARCH-linux-gcc INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl
	touch .installed
fi

######## ####################################################################
# RUST # ####################################################################
######## ####################################################################

RUST_VERSION=1.65.0
RUST_VERSION_REV=1

cd $SRC/rust

if [ ! -f .cloned ]; then
	git clone https://github.com/rust-lang/rust.git
	touch .cloned
fi

cd rust

if [ ! -f .configured ]; then
	git checkout $RUST_VERSION
	cp ../config.toml .
	touch .configured
fi

#if [ ! -f .patched ]; then
#	./x.py
#	./build/x86_64-unknown-linux-gnu/stage0/bin/cargo update -p libc
#	touch .patched
#fi

if [ ! -f .installed ]; then

	CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_RUSTFLAGS='-Ctarget-feature=-crt-static -Cstrip=symbols -Clink-arg=-Wl,--dynamic-linker=/mmc/lib/ld-musl-aarch64.so.1 -Clink-arg=-Wl,-rpath,/mmc/lib' \
	CFLAGS_aarch64_unknown_linux_musl="-mcpu=cortex-a53" \
	CXXFLAGS_aarch64_unknown_linux_musl="-mcpu=cortex-a53" \
	AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_LIB_DIR=$DEST/lib \
	AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_INCLUDE_DIR=$DEST/include \
	AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_NO_VENDOR=1 \
	AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
	DESTDIR=$BASE/aarch64-unknown-linux-musl \
	./x.py install
	touch .installed
fi

cd $BASE

if [ ! -f .prepped ]; then
	mkdir -p $BASE/aarch64-unknown-linux-musl/DEBIAN
	cp $SRC/rust/control $BASE/aarch64-unknown-linux-musl/DEBIAN
	sed -i 's,version,'"$RUST_VERSION"'-'"$RUST_VERSION_REV"',g' \
		$BASE/aarch64-unknown-linux-musl/DEBIAN/control
	touch .prepped
fi

if [ ! -f .packaged ]; then
	dpkg-deb --build aarch64-unknown-linux-musl
	dpkg-name aarch64-unknown-linux-musl.deb
	touch .packaged
fi
