TERMUX_PKG_HOMEPAGE="https://github.com/ARMSX2/ARMSX2"
TERMUX_PKG_DESCRIPTION="Native ARM64 JIT Fork of PCSX2"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="Termux Community"
TERMUX_PKG_VERSION="2.6.9"
TERMUX_PKG_SRCURL="git+https://github.com/ARMSX2/ARMSX2.git"
TERMUX_PKG_GIT_BRANCH="master"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_DEPENDS="libpcap, libc++, sdl3, ffmpeg, zstd, libcurl, freetype, libpng, libjpeg-turbo, libwebp, liblzma, vulkan-loader, libglvnd, libandroid-shmem, libandroid-stub, libxrandr, libx11, qt6-qtbase, libaio, libsoundtouch, libzip, shaderc, plutovg"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, cmake, ninja, pkg-config, vulkan-headers, extra-cmake-modules, qt6-qttools-cross-tools"
TERMUX_PKG_BUILD_IN_SRC=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_BUILD_TYPE=Release
-DUSE_WAYLAND=OFF
-DUSE_X11=ON
-DUSE_VULKAN=ON
-DUSE_OPENGL=ON
-DUSE_EGL=ON
-DUSE_QT=ON
-DENABLE_TESTS=OFF
-DUSE_BACKTRACE=OFF
"

termux_step_pre_configure() {
	# --- LINKING & COMPILATION FLAGS ---
	LDFLAGS+=" -landroid-shmem -landroid -lXrandr"
	CFLAGS+=" -fPIE"
	CXXFLAGS+=" -fPIE"

	# --- LIBBACKTRACE FIX ---
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

	# --- JNI STUB FIX: Un-guard and patch AndroidStubs.cpp ---
	local STUB_FILE="${TERMUX_PKG_SRCDIR}/pcsx2/Android/AndroidStubs.cpp"
	if [ -f "$STUB_FILE" ]; then
		# 1. Remove #ifdef ENABLE_LIBRETRO guard so stubs compile for Qt desktop
		sed -i 's/#ifdef ENABLE_LIBRETRO/#if 1/g' "$STUB_FILE"

		# 2. Append missing Native::onPadRumble stub
		cat << 'EOF' >> "$STUB_FILE"

namespace Native {
    void onPadRumble(int id, int low, int high) {}
}
EOF
	fi

	# --- PLUTOSVG: build and install into $TERMUX_PREFIX ---
	local PLUTOSVG_SRC="${TERMUX_PKG_CACHEDIR}/plutosvg"
	if [ ! -d "$PLUTOSVG_SRC" ]; then
		git clone --recursive https://github.com/sammycage/plutosvg.git "$PLUTOSVG_SRC"
	fi
	cmake -S "$PLUTOSVG_SRC" -B "$PLUTOSVG_SRC/build" \
		-DCMAKE_INSTALL_PREFIX="$TERMUX_PREFIX" \
		-DCMAKE_BUILD_TYPE=Release \
		-DPLUTOSVG_BUILD_EXAMPLES=OFF
	cmake --build "$PLUTOSVG_SRC/build" --target install
}


termux_step_make_install() {
	cmake \
		--install "${TERMUX_PKG_BUILDDIR}" \
		--prefix "${TERMUX_PREFIX}" \
		--verbose || true

	mkdir -p "${TERMUX_PREFIX}/bin"
	install -Dm755 \
		"${TERMUX_PKG_BUILDDIR}/bin/armsx2-qt" \
		"${TERMUX_PREFIX}/bin/armsx2-qt" \
	|| cp -a \
		"${TERMUX_PKG_BUILDDIR}/bin/armsx2-qt" \
		"${TERMUX_PREFIX}/bin/armsx2-qt"
		# DON'T do this — lib/ contains static archives that don't belong in the package
	cp -a "${TERMUX_PKG_BUILDDIR}/bin/." "${TERMUX_PREFIX}/bin/"  || true
	cp -a "${TERMUX_PKG_BUILDDIR}/lib/*.so" "${TERMUX_PREFIX}/lib/"  || true
}
