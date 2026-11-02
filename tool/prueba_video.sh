#!/usr/bin/env bash
# Prueba del vídeo MP4 en un dispositivo (emulador de Android, simulador de
# iPhone o Windows) y anotaciones de GitHub Actions con el resultado.
#
# Uso: bash tool/prueba_video.sh <dispositivo> [carpeta para los vídeos]
#   bash tool/prueba_video.sh emulator-5554
#   bash tool/prueba_video.sh <UDID del simulador de iPhone>
#   bash tool/prueba_video.sh windows "$PWD/build/muestras_video"
#
# Cada intento tiene un límite de tiempo (HOPE_LIMITE_PRUEBA, en segundos;
# 12 minutos por defecto). Si un intento se queda colgado, algo que a veces
# pasa con los emuladores de Android en GitHub, se repite una vez. Si la
# prueba falla de verdad, no se repite.
set -uo pipefail
cd "$(dirname "$0")/.."

device="$1"
out="${2:-}"
limite="${HOPE_LIMITE_PRUEBA:-720}"
mkdir -p build
args=(test integration_test/video_test.dart -d "$device" --reporter expanded)
if [ -n "$out" ]; then
  mkdir -p "$out"
  args+=("--dart-define=HOPE_MUESTRAS=$out")
fi

# Une las líneas con %0A para las anotaciones (awk: funciona también en macOS).
escapar() { sed -e 's/%/%25/g' -e 's/\r//g' | awk '{ if (NR > 1) printf "%%0A"; printf "%s", $0 }'; }

# ¿Es un dispositivo Android? Entonces se guarda su registro (logcat).
android=0
if command -v adb >/dev/null 2>&1 && adb -s "$device" get-state >/dev/null 2>&1; then
  android=1
fi

# Límite de tiempo con «timeout» de GNU (también en Git Bash de Windows).
con_limite() {
  if timeout --version >/dev/null 2>&1; then
    timeout --kill-after=30s "$limite" "$@"
  else
    "$@"
  fi
}

status=1
for intento in 1 2; do
  echo "::group::Prueba del vídeo en $device (intento $intento)"
  [ "$android" -eq 1 ] && adb -s "$device" logcat -c 2>/dev/null
  # La salida se muestra mientras se ejecuta, para ver dónde se para.
  con_limite flutter "${args[@]}" 2>&1 | tee build/video.log
  status=${PIPESTATUS[0]}
  echo "::endgroup::"
  if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
    ultima=$(grep -v '^\s*$' build/video.log | tail -n 1)
    echo "::warning title=Vídeo MP4 ($device)::El intento $intento superó $limite s sin terminar. Última línea: $(printf '%s' "$ultima" | escapar)"
    if [ "$android" -eq 1 ]; then
      echo "::group::Registro del emulador (logcat)"
      adb -s "$device" logcat -d -t 400 2>/dev/null | grep -E -i 'flutter|hope|AndroidRuntime|FATAL|MediaCodec|CCodec|ANR' | tail -n 200
      echo "::endgroup::"
    fi
    continue
  fi
  break
done

notas=$(grep -o 'HOPE_VIDEO: .*' build/video.log | sed 's/^HOPE_VIDEO: //' | head -n 20)
if [ -n "$notas" ]; then
  echo "::notice title=Vídeo MP4 ($device)::$(printf '%s\n' "$notas" | escapar)"
fi
if [ "$status" -ne 0 ]; then
  detalle=$( (grep -B 40 -A 10 -E '\[E\]|EXCEPTION|Error|error:' build/video.log || tail -n 80 build/video.log) | head -n 150)
  if [ "$android" -eq 1 ]; then
    detalle="$detalle
---- logcat ----
$(adb -s "$device" logcat -d -t 400 2>/dev/null | grep -E -i 'AndroidRuntime|FATAL|flutter|MediaCodec' | tail -n 40)"
  fi
  echo "::error title=Vídeo MP4 ($device)::$(printf '%s\n' "$detalle" | escapar)"
fi
exit "$status"
