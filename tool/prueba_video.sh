#!/usr/bin/env bash
# Prueba del vídeo MP4 en un dispositivo (emulador de Android o Windows) y
# anotaciones de GitHub Actions con el resultado.
#
# Uso: bash tool/prueba_video.sh <dispositivo> [carpeta para los vídeos]
#   bash tool/prueba_video.sh emulator-5554
#   bash tool/prueba_video.sh windows "$PWD/build/muestras_video"
set -uo pipefail
cd "$(dirname "$0")/.."

device="$1"
out="${2:-}"
mkdir -p build
args=(test integration_test/video_test.dart -d "$device" --reporter expanded)
if [ -n "$out" ]; then
  mkdir -p "$out"
  args+=("--dart-define=HOPE_MUESTRAS=$out")
fi

flutter "${args[@]}" > build/video.log 2>&1
status=$?
cat build/video.log

escapar() { sed -e 's/%/%25/g' -e 's/\r//g' | sed ':a;N;$!ba;s/\n/%0A/g'; }

notas=$(grep -o 'HOPE_VIDEO: .*' build/video.log | sed 's/^HOPE_VIDEO: //' | head -n 20)
if [ -n "$notas" ]; then
  echo "::notice title=Vídeo MP4 ($device)::$(printf '%s\n' "$notas" | escapar)"
fi
if [ "$status" -ne 0 ]; then
  detalle=$( (grep -B 40 -A 10 -E '\[E\]|EXCEPTION|Error|error:' build/video.log || tail -n 80 build/video.log) | head -n 150)
  echo "::error title=Vídeo MP4 ($device)::$(printf '%s\n' "$detalle" | escapar)"
fi
exit "$status"
