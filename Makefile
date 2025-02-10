PWD := $(shell pwd)
BZIP2_DIR := ${PWD}/bzip2
FREETYPE_DIR := ${PWD}/freetype
LIBMODPLUG_VERSION := '0.8.8.5'
LIBMODPLUG_DIR := ${PWD}/libmodplug
LIBOGG_DIR := ${PWD}/libogg
LIBTHEORA_DIR := ${PWD}/libtheora
LIBVORBIS_DIR := ${PWD}/libvorbis
LOVE_DIR := ${PWD}/love
LUAJIT_DIR := ${PWD}/luajit
OPENAL_DIR := ${PWD}/openal-soft
PHYSFS_DIR := ${PWD}/physfs
ZLIB_DIR := ${PWD}/zlib
SDL_DIR := ${PWD}/sdl
HARFBUZZ_DIR := ${PWD}/harfbuzz
CC := g++

all: submodule-update bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs sdl harfbuzz love

submodule-update:
	git submodule update --init --recursive

	@for submodule in $$(git config --file .gitmodules --get-regexp path | awk '{ print $$2 }'); do \
		cd $$submodule; git clean -df ; \
		branch=$$(git symbolic-ref --short HEAD 2>/dev/null || echo "Detached HEAD"); \
		tag=$$(git describe --tags --exact-match 2>/dev/null || echo "No associated tag"); \
		echo "$$submodule - Branch: [$$branch] Tag: [$$tag]"; \
		cd - >/dev/null; \
	done

BZIP2_LIB_DIR := ${BZIP2_DIR}
BZIP2_INC_DIR := ${BZIP2_DIR}
bzip2:
	cd ${BZIP2_DIR} && \
  make

ZLIB_LIB_DIR := ${ZLIB_DIR}
ZLIB_INC_DIR := ${ZLIB_DIR}
zlib:
	cd ${ZLIB_DIR} && \
    sh ./configure --static && \
    make

FREETYPE_LIB_DIR := ${FREETYPE_DIR}/objs/.libs
FREETYPE_INC_DIR := ${FREETYPE_DIR}/include
freetype:
	cd ${FREETYPE_DIR} && \
	env CPPFLAGS='-I${BZIP2_DIR} -I${ZLIB_DIR} -I${LIBOGG_DIR}' \
		LDFLAGS='-L${BZIP2_DIR} -L${ZLIB_DIR} -L${LIBOGG_DIR}' sh ./autogen.sh && ./configure --disable-shared --without-png && \
		make

# https://github.com/love2d/love/actions/runs/13228350529/job/36922098103    
libmodplug-download:
	@if [ ! -d "libmodplug-${LIBMODPLUG_VERSION}" ]; then \
		if wget --spider 'https://razaoinfo.dl.sourceforge.net/project/modplug-xmms/libmodplug/${LIBMODPLUG_VERSION}/libmodplug-${LIBMODPLUG_VERSION}.tar.gz?viasf=1'; then \
			echo "Link disponível. Iniciando download..."; \
			wget -O libmodplug.tar.gz 'https://razaoinfo.dl.sourceforge.net/project/modplug-xmms/libmodplug/${LIBMODPLUG_VERSION}/libmodplug-${LIBMODPLUG_VERSION}.tar.gz?viasf=1'; \
			tar xvfz libmodplug.tar.gz; \
			rm libmodplug.tar.gz; \
		fi \
	fi; \
	rm -rf libmodplug; \
	ln -s libmodplug-${LIBMODPLUG_VERSION} libmodplug

LIBMODPLUG_LIB_DIR := ${LIBMODPLUG_DIR}/src/.libs
LIBMODPLUG_INC_DIR := ${LIBMODPLUG_DIR}
libmodplug: libmodplug-download
	cd ${LIBMODPLUG_DIR} && \
		rm -rf build libmodplug && \
		ln -s src libmodplug && \
		sh ./configure --disable-shared && \
		make

LIBOGG_LIB_DIR := ${LIBOGG_DIR}/src/.libs
LIBOGG_INC_DIR := ${LIBOGG_DIR}/include
libogg:
	cd ${LIBOGG_DIR} && \
		sh ./autogen.sh && ./configure --disable-shared && \
		make

LIBTHEORA_LIB_DIR := ${LIBTHEORA_DIR}/lib/.libs
LIBTHEORA_INC_DIR := ${LIBTHEORA_DIR}/include
libtheora: libogg libvorbis sdl
	cd ${LIBTHEORA_DIR} && \
	sh ./autogen.sh && ./configure --disable-shared \
  --with-ogg-libraries=${LIBOGG_LIB_DIR} --with-ogg-includes=${LIBOGG_INC_DIR} \
  --with-vorbis-libraries=${LIBVORBIS_LIB_DIR} --with-vorbis-includes=${LIBVORBIS_INC_DIR} \
  --with-sdl-libraries=${SDL_LIB_DIR} --with-sdl-includes=${SDL_INC_DIR} && \
	make

LIBVORBIS_LIB_DIR := ${LIBVORBIS_DIR}/lib/.libs
LIBVORBIS_INC_DIR := ${LIBVORBIS_DIR}/include
libvorbis: libogg
	cd ${LIBVORBIS_DIR} && \
		sh ./autogen.sh && ./configure --disable-shared \
    --with-ogg-libraries=${LIBOGG_LIB_DIR} --with-ogg-includes=${LIBOGG_INC_DIR} && \
		make

LUAJIT_LIB_DIR := ${LUAJIT_DIR}/src
LUAJIT_INC_DIR := ${LUAJIT_DIR}/src
luajit:
	cd ${LUAJIT_DIR} && \
		make && \
		rm -rf src/libluajit.so

OPENAL_LIB_DIR := ${OPENAL_DIR}/build
OPENAL_INC_DIR := ${OPENAL_DIR}/include
openal:
	cd ${OPENAL_DIR} && \
		mkdir -p build && cd build && \
		cmake .. && \
		make && \
		rm -f libOpenAL.a &&\
		find CMakeFiles/openal.dir -name '*.o' | xargs ar rc libOpenAL.a

PHYSFS_LIB_DIR := ${PHYSFS_DIR}/build
PHYSFS_INC_DIR := ${PHYSFS_DIR}/src
physfs: zlib
	cd ${PHYSFS_DIR} && \
		mkdir -p build && cd build && \
		cmake -D ZLIB_INCLUDE_DIR=${ZLIB_INC_DIR} -D ZLIB_LIBRARY=${ZLIB_LIB_DIR} -D PHYSFS_INTERNAL_ZLIB=ON -D PHYSFS_BUILD_STATIC=ON -D PHYSFS_ARCHIVE_7Z=OFF -D PHYSFS_ARCHIVE_GRP=OFF -D PHYSFS_ARCHIVE_HOG=OFF -D PHYSFS_ARCHIVE_MVL=OFF -D PHYSFS_ARCHIVE_QPAK=OFF -D PHYSFS_ARCHIVE_WAD=OFF -D PHYSFS_BUILD_SHARED=OFF .. && \
		make

SDL_LIB_DIR := ${SDL_DIR}/build
SDL_INC_DIR := ${SDL_DIR}/include
sdl:
	cd ${SDL_DIR} && \
    cmake -Bbuild -D SDL_STATIC_ENABLED_BY_DEFAULT=ON && \
    cmake --build ${SDL_DIR}/build

HARFBUZZ_LIB_DIR := ${HARFBUZZ_DIR}/build
HARFBUZZ_INC_DIR := ${HARFBUZZ_DIR}/src
harfbuzz:
	cd ${HARFBUZZ_DIR} && \
    cmake -Bbuild -D BUILD_SHARED_LIBS=OFF && \
    cmake --build ${HARFBUZZ_DIR}/build

love:
	cd ${LOVE_DIR} && \
	cmake -B build -S. -D BUILD_SHARED_LIBS=OFF -D LOVE_MPG123=OFF -D LOVE_JIT=ON -Wno-dev --trace \
  -D SDL3_LIBRARIES=${SDL_LIB_DIR} -D SDL3_INCLUDE_DIRS=${SDL_INC_DIR} -DLOVE_USE_SDL3=ON -DSDL3_ROOT=${SDL_DIR} \
  -D FREETYPE_LIBRARY=${FREETYPE_LIB_DIR} -D FREETYPE_INCLUDE_DIRS=${FREETYPE_INC_DIR} \
  -D HARFBUZZ_LIBRARY=${HARFBUZZ_LIB_DIR} -D HARFBUZZ_INCLUDE_DIR=${HARFBUZZ_INC_DIR} -DHarfbuzz_ROOT=${HARFBUZZ_DIR} \
  -D OPENAL_LIBRARY=${OPENAL_LIB_DIR} -D OPENAL_INCLUDE_DIR=${OPENAL_INC_DIR} \
  -D MODPLUG_LIBRARY=${LIBMODPLUG_LIB_DIR} -D MODPLUG_INCLUDE_DIR=${LIBMODPLUG_INC_DIR} -DModPlug_ROOT=${LIBMODPLUG_DIR} \
  -D THEORA_LIBRARY=${LIBTHEORA_LIB_DIR} -D THEORADEC_LIBRARY=${LIBTHEORA_LIB_DIR} -D THEORA_INCLUDE_DIR=${LIBTHEORA_INC_DIR} -DTheora_ROOT=${LIBTHEORA_DIR} \
  -D VORBIS_LIBRARY=${LIBVORBIS_LIB_DIR} -D VORBISFILE_LIBRARY=${LIBVORBIS_LIB_DIR} -D VORBIS_INCLUDE_DIR=${LIBVORBIS_INC_DIR} \
  -D OGG_LIBRARY=${LIBOGG_LIB_DIR} -D OGG_INCLUDE_DIR=${LIBOGG_INC_DIR} -DVorbis_ROOT=${LIBOGG_DIR} \
  -D LOVE_JIT=TRUE -D LUAJIT_LIBRARY=${LUAJIT_LIB_DIR} -D LUAJIT_INCLUDE_DIR=${LUAJIT_INC_DIR} -DLuaJIT_ROOT=${LUAJIT_DIR} \
  -D ZLIB_ROOT=${ZLIB_DIR} \
  -D Ogg_ROOT=${LIBOGG_DIR}
	cd ${LOVE_DIR}/build && make

       

clean:
	(cd ${BZIP2_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${ZLIB_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${LIBTHEORA_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${LIBMODPLUG_DIR} && rm -rf build libmodplug)
	(cd ${LIBOGG_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${LIBVORBIS_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${LUAJIT_DIR} && [ -f Makefile ] && make clean || true)
	(cd ${OPENAL_DIR} && rm -rf build)
	(cd ${PHYSFS_DIR} && rm -rf build)
	(cd ${SDL2_DIR} && rm -rf build)
	(cd ${HARFBUZZ_DIR} && rm -rf build)
	(cd ${LOVE_DIR} && [ -f Makefile ] && make clean || true)
	(rm -f love2d)
  
builder:
	docker build --platform linux/amd64 -t love-libretro-builder .
	docker run -it --platform linux/amd64 -w /builder -v ${PWD}:/builder love-libretro-builder make

.PHONY: all submodule-update bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs sdl harfbuzz love clean builder
