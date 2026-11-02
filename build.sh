#!/bin/sh
# Build the Mac helper tools Kikitori downloads on first launch: an LGPL ffmpeg/ffprobe and whisper-cli, arm64.
# Output ($KT_OUT, default ./dist-tools): ffmpeg-macos-arm64.zip, whisper-cpp-macos-arm64.zip, SHA256SUMS and the two LGPL source tarballs.
# Needs: Xcode command-line tools, cmake, nasm (brew). Run it from any empty folder, e.g.  mkdir /tmp/kt && cd /tmp/kt && sh /path/to/build.sh
# Builds under $KT_BUILD (default ./kt-build). The build folder's name is kept out of the binaries (prefix maps, a neutral --prefix, and a check at the end).
# Licences: whisper.cpp MIT; ffmpeg LGPL-2.1+ (NO --enable-gpl / --enable-nonfree, so no libx264; H.264 comes from VideoToolbox);
# LAME is LGPL. Each zip carries the licence texts and BUILD-INFO.txt (versions + configure flags), and the sources are at the URLs below.
set -e
FFMPEG=9.0.2; WHISPER=v1.9.5; LAME=3.100
FFMPEG_SHA=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e; LAME_SHA=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
W=${KT_BUILD:-$PWD/kt-build}; OUT=${KT_OUT:-$PWD/dist-tools}; P=$W/build/prefix
case $W$OUT in /*/*/*) ;; *) echo "KT_BUILD and KT_OUT must be absolute paths"; exit 1;; esac
export MACOSX_DEPLOYMENT_TARGET=12.0
MAP="-ffile-prefix-map=$W=/build -fdebug-prefix-map=$W=/build"  # no build-folder path in __FILE__ strings or debug info
rm -rf "$W/build" "$OUT"; mkdir -p "$W/src" "$W/build" "$OUT"; cd "$W"

fetch() { [ -f "src/$1" ] || curl -fsSL -o "src/$1" "$2"; echo "$3  src/$1" | shasum -a 256 -c - >/dev/null || { echo "$1 does not match the pinned checksum"; exit 1; }; }
fetch lame-$LAME.tar.gz "https://downloads.sourceforge.net/project/lame/lame/$LAME/lame-$LAME.tar.gz" $LAME_SHA
fetch ffmpeg-$FFMPEG.tar.xz "https://ffmpeg.org/releases/ffmpeg-$FFMPEG.tar.xz" $FFMPEG_SHA
cd build

tar xzf ../src/lame-$LAME.tar.gz
(cd lame-$LAME && CFLAGS="-O2 $MAP" ./configure --prefix="$P" --disable-shared --enable-static --disable-frontend --disable-decoder >/dev/null && make -j8 >/dev/null && make install >/dev/null)

# The configure flags below end up inside ffmpeg (-version prints them), so they hold no folder names: the lame include/lib paths go in through the
# environment, and the install prefix is the neutral /usr/local (installed into a staging folder with DESTDIR, which also strips the binaries).
tar xJf ../src/ffmpeg-$FFMPEG.tar.xz
CFG="--prefix=/usr/local --disable-gpl --disable-nonfree --disable-doc --disable-ffplay --enable-libmp3lame --enable-videotoolbox --enable-audiotoolbox --disable-autodetect --enable-zlib --enable-iconv --extra-libs=-liconv --pkg-config-flags=--static"
(cd ffmpeg-$FFMPEG && CFLAGS="-I$P/include $MAP" LDFLAGS="-L$P/lib" ./configure $CFG >/dev/null && make -j8 >/dev/null && make install DESTDIR="$P/stage" >/dev/null && echo "ffmpeg $FFMPEG configure: $CFG" > ../ffmpeg-info)  # && not ;: a failed build must stop here, not zip an empty folder
FF=$P/stage/usr/local/bin
[ -x $FF/ffmpeg ] && [ -x $FF/ffprobe ] || { echo "ffmpeg build failed"; exit 1; }
mkdir -p pk-ff && cp $FF/ffmpeg $FF/ffprobe pk-ff/ && cp ffmpeg-$FFMPEG/COPYING.LGPLv2.1 pk-ff/ && cp lame-$LAME/COPYING pk-ff/COPYING.LAME
{ cat ffmpeg-info; echo "lame $LAME (LGPL) static"; echo "source: https://ffmpeg.org/releases/ffmpeg-$FFMPEG.tar.xz  https://lame.sourceforge.io/"; echo "built $(date -u +%F) on $(sw_vers -productVersion), arm64"; } > pk-ff/BUILD-INFO.txt
ffmpeg_ok=$(pk-ff/ffmpeg -hide_banner -version | grep -c -- "--enable-gpl" || true); [ "$ffmpeg_ok" = 0 ] || { echo "GPL build, refusing"; exit 1; }

git clone -q --depth 1 --branch $WHISPER https://github.com/ggml-org/whisper.cpp.git whisper
(cd whisper && cmake -B b -DBUILD_SHARED_LIBS=OFF -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  "-DCMAKE_C_FLAGS=$MAP" "-DCMAKE_CXX_FLAGS=$MAP" "-DCMAKE_OBJC_FLAGS=$MAP" "-DCMAKE_OBJCXX_FLAGS=$MAP" >/dev/null && cmake --build b -j8 --target whisper-cli >/dev/null)
mkdir -p pk-wh && cp whisper/b/bin/whisper-cli pk-wh/ && cp whisper/LICENSE pk-wh/LICENSE
echo "whisper.cpp $WHISPER (MIT), Metal GPU, static. source: https://github.com/ggml-org/whisper.cpp/tree/$WHISPER  built $(date -u +%F), arm64" > pk-wh/BUILD-INFO.txt

# Refuse to ship a binary or text file that names the build folder, this home folder or any /Users path.
for f in pk-ff/ffmpeg pk-ff/ffprobe pk-ff/BUILD-INFO.txt pk-wh/whisper-cli pk-wh/BUILD-INFO.txt; do
  if strings -a "$f" | grep -F -e "$W" -e "$HOME" -e "/Users/" >/dev/null; then echo "$f names a local folder:"; strings -a "$f" | grep -F -e "$W" -e "$HOME" -e "/Users/" | head -5; exit 1; fi
done
(cd pk-ff && zip -qr "$OUT/ffmpeg-macos-arm64.zip" .); (cd pk-wh && zip -qr "$OUT/whisper-cpp-macos-arm64.zip" .)
cp ../src/ffmpeg-$FFMPEG.tar.xz ../src/lame-$LAME.tar.gz "$OUT/"

cd "$OUT" && shasum -a 256 *.zip | tee SHA256SUMS; ls -lh
otool -L "$W/build/pk-ff/ffmpeg" "$W/build/pk-wh/whisper-cli" | grep -v "^/" | grep -v "/usr/lib\|/System" || true
