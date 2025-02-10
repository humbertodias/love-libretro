PWD := $(shell pwd)
BZIP2_DIR := ${PWD}/bzip2
FREETYPE_DIR := ${PWD}/freetype
LIBMODPLUG_DIR := ${PWD}/libmodplug-0.8.8.5
LIBOGG_DIR := ${PWD}/libogg
LIBTHEORA_DIR := ${PWD}/libtheora
LIBVORBIS_DIR := ${PWD}/libvorbis
LOVE_DIR := ${PWD}/love
LUAJIT_DIR := ${PWD}/LuaJIT
OPENAL_DIR := ${PWD}/openal-soft
PHYSFS_DIR := ${PWD}/physfs
ZLIB_DIR := ${PWD}/zlib
SDL_DIR := ${PWD}/sdl
CC := g++

all: submodule-update bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs sdl love

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
    autoreconf -fi && \
		env CPPFLAGS='-I${BZIP2_DIR} -I${ZLIB_DIR} -I${LIBOGG_DIR}' \
		LDFLAGS='-L${BZIP2_DIR} -L${ZLIB_DIR} -L${LIBOGG_DIR}' sh ./configure --disable-shared --without-png && \
		make
    
libmodplug:
	cd ${LIBMODPLUG_DIR} && \
		rm -rf build libmodplug && \
		ln -s src libmodplug && \
		mkdir build && cd build && \
		cmake -D CMAKE_C_FLAGS='-include stdint.h -DHAVE_SINF' -D CMAKE_CXX_FLAGS='-include stdint.h -DHAVE_SINF' .. && \
		make

libogg:
	cd ${LIBOGG_DIR} && \
    cmake -Bbuild -D BUILD_SHARED_LIBS=OFF && \
    cmake --build build

libtheora: libogg
	cd ${LIBTHEORA_DIR} && \
		env OGG_CFLAGS='-I${LIBOGG_DIR}/include' OGG_LIBS='-L${LIBOGG_DIR}/src/.libs' sh ./autogen.sh && ./configure --disable-shared && \
		make

libvorbis: libogg
	cd ${LIBVORBIS_DIR} && \
		env CPPFLAGS='-I${LIBOGG_DIR}/include' LDFLAGS='-L${LIBOGG_DIR}/src/.libs' sh ./configure --disable-shared && \
		make

luajit:
	cd ${LUAJIT_DIR} && \
		make && \
		rm -rf src/libluajit.so

openal:
	cd ${OPENAL_DIR} && \
		mkdir build && cd build && \
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

love:
	cd ${LOVE_DIR} && \
    autoreconf -fi && \
		env lua_CFLAGS='-I${LUAJIT_DIR}/src' lua_LIBS='-L${LUAJIT_DIR}/src' freetype2_CFLAGS='-I${FREETYPE_DIR}/include' freetype2_LIBS='-L${FREETYPE_DIR}/objs/.libs' openal_CFLAGS='-I${OPENAL_DIR}/include' openal_LIBS='-L${OPENAL_DIR}/build' libmodplug_CFLAGS='-I${LIBMODPLUG_DIR}' libmodplug_LIBS='-L${LIBMODPLUG_DIR}/build' vorbisfile_CFLAGS='-I${LIBOGG_DIR}/include -I${LIBVORBIS_DIR}/include' vorbisfile_LIBS='-L${LIBOGG_DIR}/src/.libs -L${LIBVORBIS_DIR}/lib/.libs' zlib_CFLAGS='-I${ZLIB_DIR}' zlib_LIBS='-L${ZLIB_DIR}' theora_CFLAGS='-I${LIBTHEORA_DIR}/include' theora_LIBS='-L${LIBTHEORA_DIR}/lib/.libs' CPPFLAGS='-I${PHYSFS_DIR}' LDFLAGS='-L${PHYSFS_DIR}/build' CPPFLAGS='-I${SDL_DIR}/include' LDFLAGS='-L${SDL_DIR}/build' sh ./configure --disable-shared --disable-mpg123 && \
		make LIBS='-lfreetype -lOpenAL -lcommon -lmodplug -logg -lvorbis -lvorbisfile -ltheora -ldl -lpthread -lluajit -lz -lSDL2' && \
		${CC} -o love2d love.o -L${LIBVORBIS_DIR}/lib/.libs -L${PHYSFS_DIR}/build ./.libs/liblove.a -L${FREETYPE_DIR}/objs/.libs -L${LUAJIT_DIR}/src -L${OPENAL_DIR}/build -L${ZLIB_DIR} -L${LIBMODPLUG_DIR}/build -L${LIBOGG_DIR}/src/.libs -L${LIBTHEORA_DIR}/lib/.libs -lSDL2 -lphysfs -L${ZLIB_DIR} -L${ZLIB_DIR} -lOpenAL -lcommon -lmodplug -lm ${LIBTHEORA_DIR}/lib/.libs/libtheora.a -ldl -lpthread -lluajit -lz -Wl,-rpath -Wl,${FREETYPE_DIR}/objs/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs -Wl,-rpath -Wl,${LIBOGG_DIR}/src/.libs/.libs

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
	(cd ${LOVE_DIR} && [ -f Makefile ] && make clean || true)
	(rm -f love2d)
  
builder:
	docker build --platform linux/amd64 -t love-libretro-builder .
	docker run -it --platform linux/amd64 -w /builder -v ${PWD}:/builder love-libretro-builder make

.PHONY: all submodule-update bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs sdl2 love clean builder