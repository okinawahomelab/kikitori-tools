# kikitori-tools

Helper tools that [Kikitori](https://kikitori.dev) downloads on Apple Silicon Macs without Homebrew (Settings › Status › Download). Kikitori checks each zip's SHA-256 before unpacking it.

| File | Contents | Licence |
|---|---|---|
| `ffmpeg-macos-arm64.zip` | `ffmpeg`, `ffprobe` 9.0.2, static, with LAME 3.100 (MP3) | LGPL-2.1-or-later (`COPYING.LGPLv2.1`, `COPYING.LAME` inside) |
| `whisper-cpp-macos-arm64.zip` | `whisper-cli` v1.9.5, Metal GPU, static | MIT (`LICENSE` inside) |

**LGPL notice.** This ffmpeg is built with `--disable-gpl --disable-nonfree`, so it contains no GPL or non-free code (no libx264; H.264 encoding uses Apple VideoToolbox). FFmpeg and LAME are free software under the GNU Lesser General Public License 2.1 or later, provided WITHOUT ANY WARRANTY. Corresponding source is attached to this release, byte-identical to the upstream downloads it was built from: `ffmpeg-9.0.2.tar.xz` (https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz) and `lame-3.100.tar.gz` (https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz). The exact configure flags are in each zip's `BUILD-INFO.txt`, and `build.sh` (attached) rebuilds both zips from those sources, so you can rebuild or replace any part of them. FFmpeg is a trademark of Fabrice Bellard; this build is not affiliated with the FFmpeg project.

**SHA-256**
```
75c29a848f3b5d248edc52bf1893637cade45804a599c06b53a158e40d404d5d  ffmpeg-macos-arm64.zip
ddc2d0ed2dbb5d07e92807ff747962a27c866dd7e4c431881439676352e4ddc8  whisper-cpp-macos-arm64.zip
8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e  ffmpeg-9.0.2.tar.xz
ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e  lame-3.100.tar.gz
```

**Licence of this repository.** `build.sh` and this README are MIT-licensed (`LICENSE`). The binaries in the release zips keep their own licences, listed in the table above.
