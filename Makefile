PWD := $(shell pwd)
BZIP2_DIR := ${PWD}/bzip2
FREETYPE_DIR := ${PWD}/freetype
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

bzip2:
	cd ${BZIP2_DIR} && \
  make

zlib:
	cd ${ZLIB_DIR} && \
    sh ./configure --static && \
		make

freetype: bzip2 zlib libogg
	cd ${FREETYPE_DIR} && \
		env CPPFLAGS='-I${BZIP2_DIR} -I${ZLIB_DIR} -I${LIBOGG_DIR}' \
		LDFLAGS='-L${BZIP2_DIR} -L${ZLIB_DIR} -L${LIBOGG_DIR}' sh ./autogen.sh && ./configure --disable-shared --without-png && \
		make
    
libmodplug-download:
	@if [ ! -d "libmodplug-0.8.9.0" ]; then \
		if wget --spider 'https://razaoinfo.dl.sourceforge.net/project/modplug-xmms/libmodplug/0.8.9.0/libmodplug-0.8.9.0.tar.gz?viasf=1'; then \
			echo "Link disponível. Iniciando download..."; \
			wget -O libmodplug.tar.gz 'https://razaoinfo.dl.sourceforge.net/project/modplug-xmms/libmodplug/0.8.9.0/libmodplug-0.8.9.0.tar.gz?viasf=1'; \
			tar xvfz libmodplug.tar.gz; \
			rm libmodplug.tar.gz; \
		fi \
	fi; \
	rm -rf libmodplug; \
	ln -s libmodplug-0.8.9.0 libmodplug

libmodplug: libmodplug-download
	cd ${LIBMODPLUG_DIR} && \
		rm -rf build libmodplug && \
		ln -s src libmodplug && \
		sh ./configure --disable-shared && \
		make

libogg:
	cd ${LIBOGG_DIR} && \
    cmake -Bbuild -D BUILD_SHARED_LIBS=OFF && \
    cmake --build build

libtheora: libogg libvorbis sdl
	cd ${LIBTHEORA_DIR} && \
	sh ./autogen.sh && ./configure --disable-shared \
  --with-ogg-libraries=${LIBOGG_DIR}/src/.libs --with-ogg-includes=${LIBOGG_DIR}/include \
  --with-vorbis-libraries=${LIBVORBIS_DIR}/src/.libs --with-vorbis-includes=${LIBVORBIS_DIR}/include \
  --with-sdl-libraries=${SDL_DIR}/src/.libs --with-sdl-includes=${SDL_DIR}/include && \
	make

libvorbis: libogg
	cd ${LIBVORBIS_DIR} && \
		sh ./autogen.sh && ./configure --disable-shared \
    --with-ogg-libraries=${LIBOGG_DIR}/src/.libs --with-ogg-includes=${LIBOGG_DIR}/include && \
		make

luajit:
	cd ${LUAJIT_DIR} && \
		make && \
		rm -rf src/libluajit.so

openal:
	cd ${OPENAL_DIR} && \
		mkdir -p build && cd build && \
		cmake .. && \
		make && \
		rm -f libOpenAL.a &&\
		find CMakeFiles/openal.dir -name '*.o' | xargs ar rc libOpenAL.a

physfs: zlib
	cd ${PHYSFS_DIR} && \
		mkdir -p build && cd build && \
		cmake -D ZLIB_INCLUDE_DIR=${ZLIB_DIR} -D ZLIB_LIBRARY=${ZLIB_DIR} -D PHYSFS_INTERNAL_ZLIB=ON -D PHYSFS_BUILD_STATIC=ON -D PHYSFS_ARCHIVE_7Z=OFF -D PHYSFS_ARCHIVE_GRP=OFF -D PHYSFS_ARCHIVE_HOG=OFF -D PHYSFS_ARCHIVE_MVL=OFF -D PHYSFS_ARCHIVE_QPAK=OFF -D PHYSFS_ARCHIVE_WAD=OFF -D PHYSFS_BUILD_SHARED=OFF .. && \
		make

sdl:
	cd ${SDL_DIR} && \
    cmake -Bbuild -D SDL_STATIC_ENABLED_BY_DEFAULT=ON && \
    cmake --build build

harfbuzz:
	cd ${HARFBUZZ_DIR} && \
    cmake -Bbuild -D BUILD_SHARED_LIBS=OFF && \
    cmake --build build

love:
	cd ${LOVE_DIR} && \
	cmake -B build -S. -D BUILD_SHARED_LIBS=OFF -D LOVE_MPG123=OFF -D LOVE_JIT=ON -Wno-dev --trace \
  -D SDL3_INCLUDE_DIRS=${SDL_DIR}/include -D SDL3_LIBRARIES=${SDL_DIR}/build \
	-D FREETYPE_LIBRARY=${FREETYPE_DIR}/objs/.libs -D FREETYPE_INCLUDE_DIRS=${FREETYPE_DIR}/include \
  -D HARFBUZZ_LIBRARY=${HARFBUZZ_DIR}/build -D HARFBUZZ_INCLUDE_DIR=${HARFBUZZ_DIR}/src \
  -D OPENAL_LIBRARY=${OPENAL_DIR}/build -D OPENAL_INCLUDE_DIR=${OPENAL_DIR}/include \
  -D MODPLUG_LIBRARY=${LIBMODPLUG_DIR}/src/.libs -D MODPLUG_INCLUDE_DIR=${LIBMODPLUG_DIR} \
  -D THEORA_LIBRARY=${LIBTHEORA_DIR}/lib/.libs -D THEORADEC_LIBRARY=${LIBTHEORA_DIR}/lib/.libs -D THEORA_INCLUDE_DIR=${LIBTHEORA_DIR}/include \
  -D VORBIS_LIBRARY=${LIBVORBIS_DIR}/lib/.libs -D VORBISFILE_LIBRARY=${LIBVORBIS_DIR}/lib/.libs -D VORBIS_INCLUDE_DIR=${LIBVORBIS_DIR}/include \
  -D OGG_LIBRARY=${LIBOGG_DIR}/build -D OGG_INCLUDE_DIR=${LIBOGG_DIR}/include \
  -D LUAJIT_LIBRARY=${LUAJIT_DIR}/src -D LUAJIT_INCLUDE_DIR=${LUAJIT_DIR}/src && \ 
	cd build && make

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
