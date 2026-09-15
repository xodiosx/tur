TERMUX_PKG_HOMEPAGE="https://github.com/ARMSX2/ARMSX2"
TERMUX_PKG_DESCRIPTION="Native ARM64 JIT Fork of PCSX2"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="Termux Community"
TERMUX_PKG_VERSION="2.6.9"
TERMUX_PKG_SRCURL="git+https://github.com/ARMSX2/ARMSX2.git"
TERMUX_PKG_GIT_BRANCH="master"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_DEPENDS="libc++, sdl3, ffmpeg, zstd, libcurl, freetype, libpng, libjpeg-turbo, libwebp, liblzma, vulkan-loader, libandroid-shmem, libx11, qt6-qtbase, libaio, libsoundtouch, libzip, shaderc, plutovg"
TERMUX_PKG_BUILD_DEPENDS="cmake, ninja, pkg-config, vulkan-headers"
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
"

termux_step_pre_configure() {
	sed -i '/function(detect_page_size)/a \ \ set(PAGE_SIZE 4096 PARENT_SCOPE)\n \ return()' "${TERMUX_PKG_SRCDIR}/cmake/Pcsx2Utils.cmake"
	sed -i '/function(detect_cache_line_size)/a \ \ set(CACHE_LINE_SIZE 64 PARENT_SCOPE)\n \ return()' "${TERMUX_PKG_SRCDIR}/cmake/Pcsx2Utils.cmake"
	LDFLAGS+=" -landroid-shmem"
	CFLAGS+=" -fPIE"
	CXXFLAGS+=" -fPIE"
}
