PWD := $(shell pwd)
BZIP2_DIR := ${PWD}/bzip2
FREETYPE_DIR := ${PWD}/freetype
LIBMODPLUG_DIR := ${PWD}/libmodplug-0.8.9.0
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

libtheora: libogg
	cd ${LIBTHEORA_DIR} && \
	sh ./autogen.sh && ./configure --disable-shared \
  --with-ogg-libraries=${LIBOGG_DIR}/src/.libs --with-ogg-includes=${LIBOGG_DIR}/include && \
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

# ./configure --disable-shared --disable-mpg123
love:
	cd ${LOVE_DIR} && \
		env lua_CFLAGS='-I${LUAJIT_DIR}/src' lua_LIBS='-L${LUAJIT_DIR}/src' freetype2_CFLAGS='-I${FREETYPE_DIR}/include' freetype2_LIBS='-L${FREETYPE_DIR}/objs/.libs' openal_CFLAGS='-I${OPENAL_DIR}/include' openal_LIBS='-L${OPENAL_DIR}/build' libmodplug_CFLAGS='-I${LIBMODPLUG_DIR}' libmodplug_LIBS='-L${LIBMODPLUG_DIR}/build' vorbisfile_CFLAGS='-I${LIBOGG_DIR}/include -I${LIBVORBIS_DIR}/include' vorbisfile_LIBS='-L${LIBOGG_DIR}/src/.libs -L${LIBVORBIS_DIR}/lib/.libs' zlib_CFLAGS='-I${ZLIB_DIR}' zlib_LIBS='-L${ZLIB_DIR}' theora_CFLAGS='-I${LIBTHEORA_DIR}/include' theora_LIBS='-L${LIBTHEORA_DIR}/lib/.libs' CPPFLAGS='-I${PHYSFS_DIR}' LDFLAGS='-L${PHYSFS_DIR}/build' CPPFLAGS='-I${SDL_DIR}/include' LDFLAGS='-L${SDL_DIR}/build' \
	sh cmake -Bbuild && \ 
	cmake --build build  && \
		make LIBS='-lfreetype -lOpenAL -lcommon -lmodplug -logg -lvorbis -lvorbisfile -ltheora -ldl -lpthread -lluajit -lz -lSDL2' && \
		${CC} -o love2d love.o -L${LIBVORBIS_DIR}/lib/.libs -L${PHYSFS_DIR}/build ./.libs/liblove.a -L${FREETYPE_DIR}/objs/.libs -L${LUAJIT_DIR}/src -L${OPENAL_DIR}/build -L${ZLIB_DIR} -L${LIBMODPLUG_DIR}/build -L${LIBOGG_DIR}/src/.libs -L${LIBTHEORA_DIR}/lib/.libs -lSDL2 -lphysfs -L${ZLIB_DIR} -L${ZLIB_DIR} -lOpenAL -lcommon -lmodplug -lm ${LIBTHEORA_DIR}/lib/.libs/libtheora.a -ldl -lpthread -lluajit -lSDL2 -lz -Wl,-rpath -Wl,${FREETYPE_DIR}/objs/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs/.libs -Wl,-rpath -Wl,${LIBVORBIS_DIR}/lib/.libs -Wl,-rpath -Wl,${LIBOGG_DIR}/src/.libs/.libs

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

.PHONY: all submodule-update bzip2 zlib freetype libmodplug libogg libtheora libvorbis luajit openal physfs sdl love clean builder
