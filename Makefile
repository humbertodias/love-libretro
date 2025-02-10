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

	@for SUBMODULE in $$(git config --file .gitmodules --get-regexp path | awk '{ print $$2 }'); do \
		echo "Processing submodule: $$SUBMODULE"; \
		cd $$SUBMODULE; \
		git clean -df; git reset HEAD --hard ;\
		\
		# Retrieve branch and tag from .gitmodules \
		BRANCH=$$(git config --file ../.gitmodules --get submodule.$$SUBMODULE.branch || echo ""); \
		TAG=$$(git config --file ../.gitmodules --get submodule.$$SUBMODULE.tag || echo ""); \
		\
		# Fallback to current branch or tag if not specified in .gitmodules \
		if [ -z "$$BRANCH" ]; then \
			BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null); \
			if [ "$$BRANCH" = "HEAD" ]; then BRANCH="Detached HEAD"; fi; \
		fi; \
		\
		if [ -z "$$TAG" ]; then \
			TAG=$$(git describe --tags --exact-match 2>/dev/null || echo ""); \
		fi; \
		\
		# Checkout logic \
		if [ "$$BRANCH" != "Detached HEAD" ]; then \
			echo "Checking out branch $$BRANCH"; \
			git checkout $$BRANCH; \
		elif [ -n "$$TAG" ]; then \
			echo "Checking out tag $$TAG"; \
			git checkout $$TAG; \
		else \
			echo "No branch or tag to checkout for $$SUBMODULE"; \
		fi; \
		\
		echo "$$SUBMODULE - Branch: [$$BRANCH] Tag: [$$TAG]"; \
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
    cmake -Bbuild -D SDL_SHARED_DEFAULT=OFF -D SDL_STATIC_DEFAULT=ON -D SDL_SHARED_AVAILABLE=OFF -D BUILD_SHARED_LIBS=OFF && \
    cd build && make

HARFBUZZ_LIB_DIR := ${HARFBUZZ_DIR}/build
HARFBUZZ_INC_DIR := ${HARFBUZZ_DIR}/src
harfbuzz:
	cd ${HARFBUZZ_DIR} && \
    cmake -Bbuild -D BUILD_SHARED_LIBS=OFF && \
    cmake --build ${HARFBUZZ_DIR}/build

LOVE_LIB_DIR := ${LOVE_DIR}/build
LOVE_INC_DIR := ${LOVE_DIR}/src
LOVE_SRC_FILES := $(shell find ${LOVE_DIR}/src -name '*.cpp')
love:
	cd ${LOVE_DIR} && \
  mkdir -p build && cd build && \
	${CC} -v -c ${LOVE_SRC_FILES} -I ${LOVE_INC_DIR}/libraries -I ${LOVE_INC_DIR} -I ${LOVE_INC_DIR}/modules -I ${LOVE_INC_DIR}/libraries/enet/libenet/include -I ${LUAJIT_INC_DIR} -I ${SDL_INC_DIR} -I ${SDL_INC_DIR}/SDL3 -I ${PHYSFS_INC_DIR} -I ${FREETYPE_INC_DIR} -I ${LIBOGG_INC_DIR} -I ${LIBTHEORA_INC_DIR} \
  -L${LIBVORBIS_LIB_DIR} -L${PHYSFS_LIB_DIR} -L${FREETYPE_LIB_DIR} -L${LUAJIT_LIB_DIR} -L${OPENAL_LIB_DIR} -L${ZLIB_LIB_DIR} -L${LIBMODPLUG_LIB_DIR} -L${LIBOGG_LIB_DIR} -L${LIBTHEORA_LIB_DIR} -L${SDL_LIB_DIR} -L${ZLIB_LIB_DIR} -L${ZLIB_LIB_DIR} -L${LIBTHEORA_LIB_DIR} \
  -lphysfs -lOpenAL -lmodplug -lm -ldl -lpthread -lluajit -lSDL3 -lz && \
  ${CC} -o love2d love.o -L${LOVE_LIB_DIR} -L${LIBVORBIS_LIB_DIR} -L${PHYSFS_LIB_DIR} -L${FREETYPE_LIB_DIR} -L${LUAJIT_LIB_DIR} -L${OPENAL_LIB_DIR} -L${ZLIB_LIB_DIR} -L${LIBMODPLUG_LIB_DIR} -L${LIBOGG_LIB_DIR} -L${LIBTHEORA_LIB_DIR}  -L${SDL_LIB_DIR} -L${ZLIB_LIB_DIR} ${LIBTHEORA_LIB_DIR} -lphysfs -lOpenAL -lmodplug -lm -ldl -lpthread -lluajit -lSDL3 -lz -Wl,-rpath -Wl,${FREETYPE_LIB_DIR} -Wl,-rpath -Wl,${LIBVORBIS_LIB_DIR} -Wl,-rpath -Wl,${LIBVORBIS_LIB_DIR} -Wl,-rpath -Wl,${LIBOGG_LIB_DIR}

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
