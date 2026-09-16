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
-DCMAKE_SYSTEM_NAME=Linux
-DCMAKE_SYSTEM_PROCESSOR=aarch64
-DUSE_WAYLAND=OFF
-DUSE_X11=ON
-DUSE_VULKAN=ON
-DUSE_QT=ON
-DENABLE_TESTS=OFF
-DUSE_BACKTRACE=OFF
-DPAGE_SIZE=4096
-DCACHE_LINE_SIZE=64
-DOVERRIDE_HOST_PAGE_SIZE=4096
-DOVERRIDE_HOST_CACHE_LINE_SIZE=64
"

termux_step_pre_configure() {
	sed -i '/function(detect_page_size)/a \ \ set(PAGE_SIZE 4096 PARENT_SCOPE)\n \ return()' "${TERMUX_PKG_SRCDIR}/cmake/Pcsx2Utils.cmake"
	sed -i '/function(detect_cache_line_size)/a \ \ set(CACHE_LINE_SIZE 64 PARENT_SCOPE)\n \ return()' "${TERMUX_PKG_SRCDIR}/cmake/Pcsx2Utils.cmake"
	sed -i 's/find_package(Libbacktrace)/# find_package(Libbacktrace)/g' "${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"
	sed -i 's/OVERRIDE_HOST_PAGE_SIZE/4096/g; s/OVERRIDE_HOST_CACHE_LINE_SIZE/64/g' \
	"${TERMUX_PKG_SRCDIR}/common/Pcsx2Defs.h"
	# --- UDEV FIX: Termux has no libudev ---
	sed -i 's/PkgConfig::LIBUDEV//g' "${TERMUX_PKG_SRCDIR}/pcsx2/CMakeLists.txt"
	sed -i 's/pkg_check_modules(LIBUDEV.*/set(LIBUDEV_FOUND FALSE)/g' \
		"${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"
	sed -i 's/find_package(PkgConfig.*LIBUDEV.*/set(LIBUDEV_FOUND FALSE)/g' \
		"${TERMUX_PKG_SRCDIR}/cmake/SearchForStuff.cmake"

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
