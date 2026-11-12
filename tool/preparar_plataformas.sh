#!/usr/bin/env bash
# Genera las carpetas de plataforma (android, ios, windows, web) que Flutter
# necesita para compilar, sin tocar el código de la app (lib/), y les aplica
# el nombre «HOPE» y los iconos.
#
# Uso: bash tool/preparar_plataformas.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Complemento propio de vídeo (packages/hope_media): flutter create añade los
# archivos de compilación de Android (Gradle) y Windows (CMake) de esta versión
# de Flutter sin tocar el código que ya existe. Lo que la plantilla trae de
# ejemplo (app de ejemplo, pruebas y la interfaz de plataforma) no se usa.
(
  cd packages/hope_media
  flutter create --no-pub --template=plugin --platforms=android,windows \
    --org io.github.joseiraburu --project-name hope_media .
  rm -rf example test android/src/test \
    lib/hope_media_platform_interface.dart lib/hope_media_method_channel.dart
  # Comprobación: los archivos de compilación tienen que existir.
  ls android/build.gradle* android/src/main/AndroidManifest.xml windows/CMakeLists.txt
)

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

# Android: recordatorios «Completa HOPE» (flutter_local_notifications) y
# análisis opcional con IA.
#   - Permisos: avisos, alarmas exactas, volver a programar los avisos al
#     reiniciar el móvil e internet (solo se usa si se activa la IA).
#   - Receptores del complemento para los avisos programados.
#   - Icono de la notificación (el óvalo de HOPE en blanco) y regla para que
#     la compilación de versión no lo elimine.
#   - «Desugaring» de Java, que el complemento necesita.
manifest=android/app/src/main/AndroidManifest.xml
if [ -f "$manifest" ] && ! grep -q 'RECEIVE_BOOT_COMPLETED' "$manifest"; then
  perl -0pi -e 's#(\s*<application)#\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>$1#' "$manifest"
  perl -0pi -e 's#(\s*</application>)#\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n            <intent-filter>\n                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>\n                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n            </intent-filter>\n        </receiver>$1#' "$manifest"
  grep -q 'ScheduledNotificationBootReceiver' "$manifest"
fi
if [ -d android/app/src/main/res ]; then
  mkdir -p android/app/src/main/res/drawable android/app/src/main/res/raw
  cat > android/app/src/main/res/drawable/ic_stat_hope.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<!-- Icono de las notificaciones de HOPE: el óvalo del logotipo, en blanco. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="1.8"
        android:pathData="M12,2.5 C15.6,2.5 18,6.8 18,12 C18,17.2 15.6,21.5 12,21.5 C8.4,21.5 6,17.2 6,12 C6,6.8 8.4,2.5 12,2.5 Z" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="1.8"
        android:strokeLineCap="round"
        android:pathData="M10.3,6.5 L10.3,17.5 M10.3,12 L12.9,12" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="1.8"
        android:pathData="M10.3,12 a2.6,2.6 0 1,0 5.2,0 a2.6,2.6 0 1,0 -5.2,0" />
</vector>
XML
  cat > android/app/src/main/res/raw/hope_keep.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<!-- El icono de las notificaciones se busca por su nombre: que la compilación
     de versión no lo elimine al quitar recursos sin usar. -->
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_hope" />
XML
fi
gradle_kts=android/app/build.gradle.kts
gradle_groovy=android/app/build.gradle
if [ -f "$gradle_kts" ] && ! grep -q 'desugar_jdk_libs' "$gradle_kts"; then
  perl -0pi -e 's#(\nandroid \{\n)#$1    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }\n#' "$gradle_kts"
  perl -pi -e 's#minSdk = flutter\.minSdkVersion#minSdk = maxOf(flutter.minSdkVersion, 24)#' "$gradle_kts"
  printf '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n' >> "$gradle_kts"
  grep -q 'isCoreLibraryDesugaringEnabled = true' "$gradle_kts"
elif [ -f "$gradle_groovy" ] && ! grep -q 'desugar_jdk_libs' "$gradle_groovy"; then
  perl -0pi -e 's#(\nandroid \{\n)#$1    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }\n#' "$gradle_groovy"
  perl -pi -e 's#minSdkVersion flutter\.minSdkVersion#minSdkVersion Math.max(flutter.minSdkVersion, 24)#' "$gradle_groovy"
  printf "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n" >> "$gradle_groovy"
  grep -q 'coreLibraryDesugaringEnabled true' "$gradle_groovy"
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
  # Idiomas de la app (sin esto, iOS solo informa del inglés y la opción
  # «Sistema» de Ajustes no elegiría el español), permiso para guardar en
  # Fotos desde la hoja de compartir y declaración de cifrado para TestFlight.
  if ! grep -q 'CFBundleLocalizations' ios/Runner/Info.plist; then
    perl -0pi -e 's#</dict>\s*</plist>\s*$#\t<key>CFBundleLocalizations</key>\n\t<array>\n\t\t<string>es</string>\n\t\t<string>en</string>\n\t</array>\n\t<key>NSPhotoLibraryAddUsageDescription</key>\n\t<string>HOPE guarda en Fotos las imágenes y vídeos que eliges guardar. / HOPE saves to Photos the images and videos you choose to save.</string>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n</dict>\n</plist>\n#' ios/Runner/Info.plist
  fi
fi
if [ -f web/manifest.json ]; then
  sed -i.bak -e 's/"name": "hope"/"name": "HOPE"/' -e 's/"short_name": "hope"/"short_name": "HOPE"/' web/manifest.json
  rm -f web/manifest.json.bak
fi

flutter pub get

# Iconos a partir del logo. Si fallara, la app se compila igual con el icono
# por defecto de Flutter.
dart run flutter_launcher_icons || echo "Aviso: no se pudieron generar los iconos."
