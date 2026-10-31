#!/usr/bin/env bash
# Genera las carpetas de plataforma (android, ios, windows, web) que Flutter
# necesita para compilar, sin tocar el código de la app (lib/), y les aplica
# el nombre «HOPE» y los iconos.
#
# Uso: bash tool/preparar_plataformas.sh
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create \
  --platforms=android,ios,windows,web \
  --project-name hope \
  --org io.github.joseiraburu \
  --description "HOPE: registro visual del dolor neuropático crónico" \
  .

# flutter create añade una prueba de ejemplo si no existe; la nuestra se llama
# igual, así que no debería aparecer, pero por si acaso se elimina.
if grep -q "Counter increments smoke test" test/widget_test.dart 2>/dev/null; then
  git checkout -- test/widget_test.dart 2>/dev/null || true
fi

# Nombre visible de la app.
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i.bak 's/android:label="hope"/android:label="HOPE"/' android/app/src/main/AndroidManifest.xml
  rm -f android/app/src/main/AndroidManifest.xml.bak
fi
if [ -f windows/runner/main.cpp ]; then
  sed -i.bak 's/L"hope"/L"HOPE"/' windows/runner/main.cpp
  sed -i.bak 's/Win32Window::Size size(1280, 720);/Win32Window::Size size(1280, 820);/' windows/runner/main.cpp
  rm -f windows/runner/main.cpp.bak
fi
if [ -f windows/runner/Runner.rc ]; then
  sed -i.bak -e 's/"FileDescription", "hope"/"FileDescription", "HOPE"/' \
             -e 's/"ProductName", "hope"/"ProductName", "HOPE"/' windows/runner/Runner.rc
  rm -f windows/runner/Runner.rc.bak
fi
if [ -f ios/Runner/Info.plist ]; then
  # CFBundleDisplayName suele ser "Hope"; lo dejamos en mayúsculas.
  sed -i.bak 's#<string>Hope</string>#<string>HOPE</string>#' ios/Runner/Info.plist
  rm -f ios/Runner/Info.plist.bak
fi
if [ -f web/manifest.json ]; then
  sed -i.bak -e 's/"name": "hope"/"name": "HOPE"/' -e 's/"short_name": "hope"/"short_name": "HOPE"/' web/manifest.json
  rm -f web/manifest.json.bak
fi

flutter pub get

# Iconos a partir del logo. Si fallara, la app se compila igual con el icono
# por defecto de Flutter.
dart run flutter_launcher_icons || echo "Aviso: no se pudieron generar los iconos."
