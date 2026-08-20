TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_SRCURL="git+https://github.com/hrydgard/ppsspp"
TERMUX_PKG_DEPENDS="libcurl, libpng, miniupnpc, zlib, libzip, glew, libsnappy, ffmpeg, libcpufeatures, rapidjson, sdl2, sdl2-ttf, fontconfig"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, libglvnd-dev, vulkan-headers, rapidjson, spirv-headers, spirv-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DCMAKE_SYSTEM_PROCESSOR=aarch64
-DUSE_SYSTEM_FFMPEG=ON
-DUSE_SYSTEM_LIBZIP=ON
-DUSE_SYSTEM_SNAPPY=ON
-DUSING_GLES2=OFF
-DUSING_QT_UI=OFF
-DHEADLESS=OFF
-DBUILD_TESTING=OFF
-DCMAKE_PREFIX_PATH=${TERMUX_PREFIX}
-DSDL2_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2.so
-DSDL2_TTF_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_TTF_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2_ttf.so
"

termux_step_pre_configure() {
	# Prevent GLEW from trying to include missing GL/glu.h
	#CFLAGS+=" -DGLEW_NO_GLU"
	#CXXFLAGS+=" -DGLEW_NO_GLU"

	cd "$TERMUX_PKG_SRCDIR"
	sed -i 's/Arm64EmitterTest();/\/\/ Arm64EmitterTest();/' UI/NativeApp.cpp
	#sed -i '403s/.*/#if 0/' Common/GPU/OpenGL/GLFeatures.cpp
	#sed -i '456s/.*/#if 0/' Common/GPU/OpenGL/GLFeatures.cpp
	#sed -i '194s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.h
	#sed -i '192s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '350s/.*/#if 1/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '503s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '752s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '155s/.*/#elif 0/' Common/GPU/Vulkan/VulkanContext.cpp
	#sed -i '1063s/.*/#if 0/' Common/GPU/Vulkan/VulkanContext.cpp
	#sed -i '145s/.*/#elif 1/' Core/Instance.cpp
	#sed -i '182s/.*/#elif 1/' Core/Instance.cpp
}

termux_step_post_make_install() {
	install -Dm700 "$TERMUX_PKG_BUILDDIR/PPSSPPSDL" \
		"$TERMUX_PREFIX/bin/PPSSPPSDL"

	# PPSSPP looks for assets/ relative to its own binary.
	mkdir -p "$TERMUX_PREFIX/share/ppsspp"
	cp -r "$TERMUX_PKG_BUILDDIR/assets" "$TERMUX_PREFIX/share/ppsspp/"
}
