#!/bin/bash
# Rebuilds dxgi.dll, d3d11.dll and d3d10core.dll from DXVK v3.0.1 with
# dxvk-waitforvblank-wine.patch applied. All three are shipped together so
# they share one toolchain/CRT (DXVK passes C++ objects between them).
# Needs meson, ninja, mingw64-gcc-c++ and glslang (e.g. inside a toolbox).
set -e
cd "$(dirname "$0")"
here="$PWD"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
git clone -q --depth 1 --branch v3.0.1 --recurse-submodules --shallow-submodules \
  https://github.com/doitsujin/dxvk.git "$work/dxvk"
cd "$work/dxvk"
git apply "$here/dxvk-waitforvblank-wine.patch"
meson setup --cross-file build-win64.txt --buildtype release build.w64
ninja -C build.w64 src/dxgi/dxgi.dll src/d3d11/d3d11.dll src/d3d10/d3d10core.dll
for d in dxgi/dxgi d3d11/d3d11 d3d10/d3d10core; do
  x86_64-w64-mingw32-strip -o "$here/${d#*/}.dll" "build.w64/src/$d.dll"
done
echo "DXVK 3.0.1 (patched) rebuilt successfully"
