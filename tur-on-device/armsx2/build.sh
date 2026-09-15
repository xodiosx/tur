TERMUX_PKG_HOMEPAGE="https://github.com/ARMSX2/ARMSX2"
TERMUX_PKG_DESCRIPTION="Native ARM64 JIT Fork of PCSX2"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@xodiosx"
TERMUX_PKG_VERSION="2.6.9"
TERMUX_PKG_SRCURL="git+https://github.com/ARMSX2/ARMSX2.git"
TERMUX_PKG_GIT_BRANCH="main"
TERMUX_PKG_DEPENDS="libc++, sdl2, ffmpeg, zstd, libcurl, freetype, libpng, libjpeg-turbo, libwebp, liblzma, vulkan-loader, libandroid-shmem, wayland, libx11, qt6-qtbase, qt6-qtwayland, libaio, libsoundtouch, libzip, shaderc"
TERMUX_PKG_BUILD_DEPENDS="cmake, ninja, pkg-config, vulkan-headers"
TERMUX_PKG_BUILD_IN_SRC=false

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_BUILD_TYPE=Release
-DCMAKE_SYSTEM_NAME=Linux
-DUSE_WAYLAND=ON
-DUSE_X11=ON
-DUSE_VULKAN=ON
-DUSE_QT=ON
-DENABLE_TESTS=OFF
"

termux_step_pre_configure() {
    # 1. Inject libandroid-shmem to emulate POSIX shared memory for PS2 hardware mapping.
    # 2. Add PIE flags to satisfy Android's W^X execution requirements for the JIT.
    LDFLAGS+=" -landroid-shmem"
    CFLAGS+=" -fPIE"
    CXXFLAGS+=" -fPIE"
}
