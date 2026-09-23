#!/bin/bash
set -euxo pipefail

function cmakebuild() {
  cd $1
  if [[ ! -z "${2:-}" ]]; then
    git checkout $2
  fi
  if [[ -f ".gitmodules" ]]; then
    git submodule update --init
  fi
  mkdir build
  cd build
  cmake ${CMAKE_ARGS:-} ..
  make
  make install
  cd ../..
  rm -rf $1
}

cd /tmp

# Debian bullseye's security suite (bullseye-security) has been decommissioned
# from the mirror network now that bullseye is EOL: apt-get update still fetches
# a Packages index that references it, but the actual .deb files 404 everywhere
# (confirmed against multiple independent mirrors, not just deb.debian.org's CDN).
# Drop it and use only bullseye/bullseye-updates. This leaves a handful of
# already-installed base-image packages (pulled in at whatever point the
# debian:bullseye-slim image was last built from the now-gone security pool)
# one patch level ahead of what -dev packages here require as an exact match;
# apt won't downgrade those on its own even with --allow-downgrades unless they
# are explicitly named, so pin them down first.
{
  echo 'deb http://deb.debian.org/debian bullseye main'
  echo 'deb http://deb.debian.org/debian bullseye-updates main'
} > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*.list
apt-get update
apt-get -y --allow-downgrades install \
  libc6=2.31-13+deb11u11 \
  libsepol1=3.1-1 \
  libudev1=247.3-7+deb11u5 \
  perl-base=5.32.1-4+deb11u3

STATIC_PACKAGES="libfftw3-bin python3 python3-setuptools netcat-openbsd libsndfile1 liblapack3 libusb-1.0-0 libqt5core5a libreadline8 libgfortran5 libgomp1 libasound2 libudev1 ca-certificates libpulse0 libfaad2 libopus0 libboost-program-options1.74.0 libboost-log1.74.0 libcurl4 alsa-utils libpopt0 libliquid2d libconfig9 libconfig++9v5 imagemagick libncurses6 libliquid2d dablin libqcustomplot2.0 libsqlite3-0"
BUILD_PACKAGES="wget git libsndfile1-dev libfftw3-dev cmake make gcc g++ liblapack-dev texinfo gfortran libusb-1.0-0-dev qtbase5-dev qtmultimedia5-dev qttools5-dev libqt5serialport5-dev qttools5-dev-tools asciidoctor asciidoc libasound2-dev libudev-dev libhamlib-dev patch xsltproc qt5-qmake libfaad-dev libopus-dev libboost-dev libboost-program-options-dev libboost-log-dev libboost-regex-dev libpulse-dev libcurl4-openssl-dev libpopt-dev libliquid-dev libconfig++-dev libncurses-dev libliquid-dev autoconf build-essential automake libqcustomplot-dev libsqlite3-dev"
apt-get -y install auto-apt-proxy
apt-get -y install --no-install-recommends $STATIC_PACKAGES $BUILD_PACKAGES

export MARCH=native
case `uname -m` in
    arm*)
        PLATFORM=armhf
	#echo Delaying ARMv7 build by 10min
	#sleep 600 # delay armhf build, so the OOM wont kill the process
        ;;
    aarch64*)
        PLATFORM=aarch64
        ;;
    x86_64*)
        PLATFORM=amd64
        export MARCH=x86-64
        ;;
esac

wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-${PLATFORM}.tar.gz
tar xzf s6-overlay-${PLATFORM}.tar.gz -C /
rm s6-overlay-${PLATFORM}.tar.gz

# upstream redsea switched its build system from autotools to Meson after
# v0.21 (no more autogen.sh/configure) — pin to the last autotools release so
# the rest of this script doesn't need meson/ninja added as build deps.
git clone https://github.com/windytan/redsea.git
pushd redsea
git checkout v0.21
./autogen.sh
./configure
make
make install
popd

JS8CALL_VERSION=2.2.0
JS8CALL_DIR=js8call
# files.js8call.com has an expired certificate and the project has since moved
# to a different fork/site structure, so the original download URL is dead.
# Debian ships the exact same 2.2.0 source (repackaged as "+ds") in its own
# pool, which is unaffected by that and gives byte-identical sources the patch
# below was written against.
JS8CALL_TGZ=js8call_${JS8CALL_VERSION}+ds.orig.tar.xz
wget http://deb.debian.org/debian/pool/main/j/js8call/${JS8CALL_TGZ}
tar xf ${JS8CALL_TGZ}
# patch allows us to build against the packaged hamlib
patch -Np1 -d ${JS8CALL_DIR} < /js8call-hamlib.patch
rm /js8call-hamlib.patch
# Debian's "+ds" repackaging strips vendored third-party sources (qcustomplot,
# sqlite3) and a non-free ephemeris data file that the original tarball used
# to bundle; link against the system libqcustomplot/libsqlite3 packages
# instead (same fix Debian's own js8call package uses) and skip installing
# the now-missing ephemeris file.
patch -Np1 -d ${JS8CALL_DIR} < /qcustomplot-link.patch
rm /qcustomplot-link.patch
patch -Np1 -d ${JS8CALL_DIR} < /sqlite-link.patch
rm /sqlite-link.patch
patch -Np1 -d ${JS8CALL_DIR} < /jpleph-wsjtx.patch
rm /jpleph-wsjtx.patch
cmakebuild ${JS8CALL_DIR}
rm ${JS8CALL_TGZ}

WSJT_DIR=wsjtx-2.6.1
WSJT_TGZ=${WSJT_DIR}.tgz
wget https://downloads.sourceforge.net/project/wsjt/${WSJT_DIR}/${WSJT_TGZ}
tar xfz ${WSJT_TGZ}
patch -Np0 -d ${WSJT_DIR} < /wsjtx-hamlib.patch
cp /wsjtx.patch ${WSJT_DIR}
cmakebuild ${WSJT_DIR}
rm ${WSJT_TGZ}

git clone https://github.com/flightaware/dump1090.git
pushd dump1090
make dump1090
cp dump1090 /usr/local/bin/
popd
rm -rf dump1090

git clone https://github.com/alexander-sholohov/msk144decoder.git
# latest from main as of 2023-02-21
MAKEFLAGS="" cmakebuild msk144decoder fe2991681e455636e258e83c29fd4b2a72d16095

git clone --depth 1 -b 1.6 https://github.com/wb2osz/direwolf.git
cd direwolf
# hamlib is present (necessary for the wsjt-x and js8call builds) and would be used, but there's no real need.
# this patch prevents direwolf from linking to it, and it can be stripped at the end of the script.
patch -Np1 < /direwolf-hamlib.patch
mkdir build
cd build
cmake ..
make
make install
cd ../..
rm -rf direwolf
# strip lots of generic documentation that will never be read inside a docker container
rm /usr/local/share/doc/direwolf/*.pdf
# examples are pointless, too
rm -rf /usr/local/share/doc/direwolf/examples/

git clone https://github.com/drowe67/codec2.git
cd codec2
# latest commit from master as of 2020-10-04
#git checkout 55d7bb8d1bddf881bdbfcb971a718b83e6344598
mkdir build
cd build
cmake ..
make
make install
install -m 0755 src/freedv_rx /usr/local/bin
cd ../..
rm -rf codec2

wget https://downloads.sourceforge.net/project/drm/dream/2.1.1/dream-2.1.1-svn808.tar.gz
tar xvfz dream-2.1.1-svn808.tar.gz
pushd dream
patch -Np0 < /dream.patch
qmake CONFIG+=console
make
make install
popd
rm -rf dream
rm dream-2.1.1-svn808.tar.gz

git clone https://github.com/mobilinkd/m17-cxx-demod.git
cmakebuild m17-cxx-demod v2.3

git clone https://github.com/szpajder/libacars.git
cmakebuild libacars v2.1.4

git clone https://github.com/TLeconte/acarsdec.git
sed -i 's/-march=native/-march='${MARCH}'/g' acarsdec/CMakeLists.txt
cmakebuild acarsdec

git clone https://github.com/szpajder/dumphfdl.git
cmakebuild dumphfdl v1.4.1

git clone https://github.com/szpajder/dumpvdl2.git
cmakebuild dumpvdl2

git clone https://github.com/EliasOenal/multimon-ng.git
cmakebuild multimon-ng 1.2.0

git clone https://github.com/hessu/aprs-symbols /usr/share/aprs-symbols
pushd /usr/share/aprs-symbols
git checkout 5c2abe2658ee4d2563f3c73b90c6f59124839802
# remove unused files (including git meta information)
rm -rf .git aprs-symbols.ai aprs-sym-export.js
popd

git clone https://github.com/0xAF/rockprog-linux
cd rockprog-linux
make
cp rockprog /usr/local/bin/
cd ..
rm -rf rockprog-linux

apt-get -y purge --autoremove $BUILD_PACKAGES
apt-get clean
rm -rf /var/lib/apt/lists/*
