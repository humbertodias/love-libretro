PWD := $(shell pwd)
BZIP2_DIR := ${PWD}/bzip2-1.0.6
FREETYPE_DIR := ${PWD}/freetype-2.5.5
LIBMODPLUG_DIR := ${PWD}/libmodplug-0.8.8.5
LIBOGG_DIR := ${PWD}/libogg-1.3.2
LIBTHEORA_DIR := ${PWD}/libtheora-1.1.1
LIBVORBIS_DIR := ${PWD}/libvorbis-1.3.5
LOVE_DIR := ${PWD}/love-0.10.2
LUAJIT_DIR := ${PWD}/LuaJIT-2.1.0-beta2
OPENAL_DIR := ${PWD}/openal-soft-1.18.0
PHYSFS_DIR := ${PWD}/physfs-2.0.3
ZLIB_DIR := ${PWD}/zlib-1.2.8

all: bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs love

bzip2:
	cd ${BZIP2_DIR} && \
		make

zlib:
	cd ${ZLIB_DIR} && \
		sh ./configure --static && \
		make

freetype: bzip2 zlib libogg
	cd ${LIBTHEORA_DIR} && \
		env CPPFLAGS='-I${BZIP2_DIR} -I${ZLIB_DIR}' \
		LDFLAGS='-L${BZIP2_DIR} -L${ZLIB_DIR}' sh ./configure --without-png && \
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
		sh ./configure --disable-shared && \
		make

libtheora: libogg
	cd ${LIBTHEORA_DIR} && \
		env CPPFLAGS='-I${LIBOGG_DIR}/include' LDFLAGS='-L${LIBOGG_DIR}/src/.libs' sh ./configure --disable-shared && \
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

physfs:
	cd ${PHYSFS_DIR} && \
		mkdir -p build && cd build && \
		cmake -D ZLIB_INCLUDE_DIR=${ZLIB_DIR} -D ZLIB_LIBRARY=${ZLIB_DIR} -D PHYSFS_ARCHIVE_7Z=OFF -D PHYSFS_ARCHIVE_GRP=OFF -D PHYSFS_ARCHIVE_HOG=OFF -D PHYSFS_ARCHIVE_MVL=OFF -D PHYSFS_ARCHIVE_QPAK=OFF -D PHYSFS_ARCHIVE_WAD=OFF -D PHYSFS_BUILD_SHARED=OFF .. && \
		make

love:
	cd ${LOVE_DIR} && \
		env lua_CFLAGS='-I${LUAJIT_DIR}/src' lua_LIBS='-L${LUAJIT_DIR}/src' freetype2_CFLAGS='-I${FREETYPE_DIR}/include' freetype2_LIBS='-L${FREETYPE_DIR}/objs/.libs' openal_CFLAGS='-I${OPENAL_DIR}/include' openal_LIBS='-L${OPENAL_DIR}/build' libmodplug_CFLAGS='-I${LIBMODPLUG_DIR}' libmodplug_LIBS='-L${LIBMODPLUG_DIR}/build' vorbisfile_CFLAGS='-I${LIBOGG_DIR}/include -I${LIBVORBIS_DIR}/include' vorbisfile_LIBS='-L${LIBOGG_DIR}/src/.libs -L${LIBVORBIS_DIR}/lib/.libs' zlib_CFLAGS='-I${ZLIB_DIR}' zlib_LIBS='-L${ZLIB_DIR}' theora_CFLAGS='-I${LIBTHEORA_DIR}/include' theora_LIBS='-L${LIBTHEORA_DIR}/lib/.libs' CPPFLAGS='-I${PHYSFS_DIR}' LDFLAGS='-L${PHYSFS_DIR}/build' sh ./configure --disable-shared --disable-mpg123 && \
		make LIBS='-lfreetype -lOpenAL -lcommon -lmodplug -logg -lvorbis -lvorbisfile -ltheora -ldl -lpthread -lluajit -lz' && \
		g++ -o love love.o  -L${LIBVORBIS_DIR}/lib/.libs -L${PHYSFS_DIR}/build ./.libs/liblove.a -L${FREETYPE_DIR}/objs/.libs -L${LUAJIT_DIR}/src -L${OPENAL_DIR}/build -L${ZLIB_DIR} -L${LIBMODPLUG_DIR}/build -L${LIBOGG_DIR}/src/.libs -L${LIBTHEORA_DIR}/lib/.libs -lSDL2 -lphysfs -L${ZLIB_DIR} -L${ZLIB_DIR} -lOpenAL -lcommon -lmodplug -lm ${LIBTHEORA_DIR}/lib/.libs/libtheora.a -ldl -lpthread -lluajit -lz -Wl,-rpath -Wl,${FREETYPE_DIR}/objs/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs -Wl,-rpath -Wl,${LIBOGG_DIR}/src/.libs/.libs

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
	(cd ${LOVE_DIR} && [ -f Makefile ] && make clean || true)
	(rm -f love)