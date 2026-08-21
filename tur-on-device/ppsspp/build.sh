TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_SRCURL="git+https://github.com/hrydgard/ppsspp"
TERMUX_PKG_DEPENDS="libcurl, libpng, miniupnpc, zlib, libzip, glew, libsnappy, ffmpeg, libcpufeatures, rapidjson, sdl2, sdl2-ttf, fontconfig"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, libglvnd-dev, vulkan-headers, rapidjson, spirv-headers, spirv-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DBUILD_TESTING=OFF
-DUSING_EGL=ON
-DUSING_FBDEV=OFF
-DUSING_GLES2=ON
-DUSING_X11_VULKAN=ON
-DUSE_WAYLAND_WSI=OFF
-DUSE_VULKAN_DISPLAY_KHR=OFF
-DUSING_QT_UI=OFF
-DMOBILE_DEVICE=OFF
-DHEADLESS=ON
-DATLAS_TOOL=ON
-DUNITTEST=OFF
-DSIMULATOR=OFF
-DLIBRETRO=OFF
-DUSE_LIBNX=OFF
-DUSE_FFMPEG=ON
-DUSE_DISCORD=OFF
-DUSE_MINIUPNPC=ON
-DUSE_SYSTEM_SNAPPY=ON
-DUSE_SYSTEM_FFMPEG=ON
-DUSE_SYSTEM_FREETYPE=ON
-DUSE_SYSTEM_LIBCHDR=OFF
-DUSE_SYSTEM_LIBZIP=ON
-DUSE_SYSTEM_LIBSDL2=ON
-DUSE_SYSTEM_LIBPNG=ON
-DUSE_SYSTEM_RAPIDJSON=ON
-DUSE_SYSTEM_ZSTD=ON
-DUSE_SYSTEM_MINIUPNPC=ON
-DUSE_ASAN=OFF
-DUSE_UBSAN=OFF
-DUSE_CCACHE=OFF
-DUSE_NO_MMAP=OFF
-DGOLD=OFF
-DBUILD_TESTING=OFF
-DCMAKE_PREFIX_PATH=${TERMUX_PREFIX}
-DSDL2_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2.so
-DSDL2_TTF_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_TTF_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2_ttf.so
"

termux_step_pre_configure() {
	cd "$TERMUX_PKG_SRCDIR"
	sed -i 's/Arm64EmitterTest();/\/\/ Arm64EmitterTest();/' UI/NativeApp.cpp
	sed -i 's/ArmEmitterTest();/\/\/ ArmEmitterTest();/' UI/NativeApp.cpp
	sed -i 's/install(PROGRAMS external-ip.sh/install(CODE "MESSAGE(\\"Skipping external-ip.sh\\")" # PROGRAMS external-ip.sh/' file
	# Patch cpu_features so empty CMAKE_SYSTEM_PROCESSOR is inferred from compiler
	sed -i '/set(PROCESSOR_IS_LOONGARCH FALSE)/a\
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "")\
	if(CMAKE_C_COMPILER_TARGET MATCHES "aarch64|arm64")\
		set(CMAKE_SYSTEM_PROCESSOR "aarch64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "armv7|arm-linux-androideabi")\
		set(CMAKE_SYSTEM_PROCESSOR "arm")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "x86_64|amd64")\
		set(CMAKE_SYSTEM_PROCESSOR "x86_64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "i686|i586|i486|i386")\
		set(CMAKE_SYSTEM_PROCESSOR "i686")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "riscv64|riscv")\
		set(CMAKE_SYSTEM_PROCESSOR "riscv64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "loongarch64|loongarch")\
		set(CMAKE_SYSTEM_PROCESSOR "loongarch64")\
	elseif(CMAKE_C_COMPILER MATCHES "aarch64|arm64")\
		set(CMAKE_SYSTEM_PROCESSOR "aarch64")\
	elseif(CMAKE_C_COMPILER MATCHES "armv7|arm-linux-androideabi")\
		set(CMAKE_SYSTEM_PROCESSOR "arm")\
	elseif(CMAKE_C_COMPILER MATCHES "x86_64|amd64")\
		set(CMAKE_SYSTEM_PROCESSOR "x86_64")\
	elseif(CMAKE_C_COMPILER MATCHES "i686|i586|i486|i386")\
		set(CMAKE_SYSTEM_PROCESSOR "i686")\
	elseif(CMAKE_C_COMPILER MATCHES "riscv64|riscv")\
		set(CMAKE_SYSTEM_PROCESSOR "riscv64")\
	elseif(CMAKE_C_COMPILER MATCHES "loongarch64|loongarch")\
		set(CMAKE_SYSTEM_PROCESSOR "loongarch64")\
	else()\
		message(FATAL_ERROR "Cannot infer CMAKE_SYSTEM_PROCESSOR from compiler")\
	endif()\
endif()' \
		ext/cmake/cpu_features/CMakeLists.txt
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
	rm -rf "${TERMUX_PREFIX}/lib/*.a"

	# Install the binary as "ppsspp" instead of "PPSSPPSDL"
	install -Dm700 "$TERMUX_PKG_BUILDDIR/PPSSPPSDL" \
		"$TERMUX_PREFIX/bin/ppsspp"

	# Optional: create a symlink for backwards compatibility
	ln -sf "$TERMUX_PREFIX/bin/ppsspp" "$TERMUX_PREFIX/bin/PPSSPPSDL"

	# Copy assets as before
	mkdir -p "$TERMUX_PREFIX/share/ppsspp"
	cp -r "$TERMUX_PKG_BUILDDIR/assets" "$TERMUX_PREFIX/share/ppsspp/"

	# Rename any references to PPSSPPSDL in text files inside the package

	find "$TERMUX_PREFIX" -type f \
		\( -name '*.desktop' -o -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.conf' -o -name '*.ini' \) \
		-exec sed -i 's/PPSSPPSDL/ppsspp/g' {} \;
}
