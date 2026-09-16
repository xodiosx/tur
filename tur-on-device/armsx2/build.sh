TERMUX_PKG_HOMEPAGE="https://github.com/ARMSX2/ARMSX2"
TERMUX_PKG_DESCRIPTION="Native ARM64 JIT Fork of PCSX2"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="Termux Community"
TERMUX_PKG_VERSION="2.6.9"
TERMUX_PKG_SRCURL="git+https://github.com/ARMSX2/ARMSX2.git"
TERMUX_PKG_GIT_BRANCH="master"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_DEPENDS="libpcap, libc++, sdl3, ffmpeg, zstd, libcurl, freetype, libpng, libjpeg-turbo, libwebp, liblzma, vulkan-loader, libandroid-shmem, libx11, qt6-qtbase, libaio, libsoundtouch, libzip, shaderc, plutovg"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, cmake, ninja, pkg-config, vulkan-headers, extra-cmake-modules, qt6-qttools, qt6-qttools-cross-tools"
TERMUX_PKG_BUILD_IN_SRC=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_BUILD_TYPE=Release
-DUSE_WAYLAND=OFF
-DUSE_X11=ON
-DUSE_VULKAN=ON
-DUSE_QT=ON
-DENABLE_TESTS=OFF
-DUSE_BACKTRACE=OFF
"

termux_step_pre_configure() {
	sed -i 's/find_package(Libbacktrace)/# find_package(Libbacktrace)/g' "${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"
	# --- UDEV FIX: strip libudev from CMake ---
	sed -i 's/PkgConfig::LIBUDEV//g' "${TERMUX_PKG_SRCDIR}/pcsx2/CMakeLists.txt"
	sed -i 's/pkg_check_modules(LIBUDEV.*/set(LIBUDEV_FOUND FALSE)/g' \
		"${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"
	sed -i 's/find_package(PkgConfig.*LIBUDEV.*/set(LIBUDEV_FOUND FALSE)/g' \
		"${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"
	# --- UDEV FIX: replace Linux DriveUtility.cpp with a no-op stub ---
	cat > "${TERMUX_PKG_SRCDIR}/pcsx2/CDVD/Linux/DriveUtility.cpp" <<-'EOF'
	// SPDX-FileCopyrightText: 2002-2026 PCSX2 Dev Team
	// SPDX-License-Identifier: GPL-3.0+
	// Termux patch: libudev is not available on Android, so optical drive
	// enumeration is stubbed out. This is not a functional loss on Android.

	#include "CDVD/CDVDdiscReader.h"

	std::vector<std::string> GetOpticalDriveList()
	{
		return {};
	}

	void GetValidDrive(std::string& drive)
	{
		drive.clear();
	}
	EOF

	# Compile and install plutosvg into $TERMUX_PREFIX
	local PLUTOSVG_SRC="${TERMUX_PKG_CACHEDIR}/plutosvg"
	if [ ! -d "$PLUTOSVG_SRC" ]; then
		git clone --recursive https://github.com/sammycage/plutosvg.git "$PLUTOSVG_SRC"
	fi
	cmake -S "$PLUTOSVG_SRC" -B "$PLUTOSVG_SRC/build" \
		-DCMAKE_INSTALL_PREFIX="$TERMUX_PREFIX" \
		-DCMAKE_BUILD_TYPE=Release \
		-DPLUTOSVG_BUILD_EXAMPLES=OFF
	cmake --build "$PLUTOSVG_SRC/build" --target install

	LDFLAGS+=" -landroid-shmem"
	CFLAGS+=" -fPIE"
	CXXFLAGS+=" -fPIE"
}
