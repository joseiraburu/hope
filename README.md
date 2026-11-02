<p align="center">
  <img src="assets/icon/logo-ovalo.svg" alt="Logo de HOPE" height="140">
</p>

# HOPE

**HOPE** es una app gratuita y de código abierto para registrar y **mostrar** el dolor neuropático crónico: dónde duele, con qué intensidad y cómo son los pinchazos, quemazones o punzadas. Convierte cada estado en una animación en bucle que se guarda en un histórico, se comparte como imagen, GIF o vídeo con el médico, la familia o las amistades, y se sigue en gráficas junto a los tratamientos y la alimentación.

Nace de la experiencia de una persona que lleva 15 años con una neuropatía sensitiva de fibra fina idiopática, con el deseo de ayudar a cualquiera que viva algo parecido.

> HOPE es una herramienta de registro personal. **No es un producto sanitario**: no diagnostica, no recomienda tratamientos y no sustituye la consulta con profesionales sanitarios.

## Descargar e instalar

Las versiones listas para instalar están en la pestaña **[Releases](https://github.com/joseiraburu/hope/releases)**.

| Sistema | Archivo | Cómo instalarlo |
| --- | --- | --- |
| Android 8 o superior | `HOPE-…-android.apk` | Ábrelo en el móvil. Si lo pide, permite «Instalar aplicaciones de origen desconocido». |
| Windows 10/11 | `HOPE-…-windows-instalador.exe` | Ejecútalo. Si aparece «Windows protegió su PC», pulsa «Más información» → «Ejecutar de todas formas». |
| Windows (sin instalar) | `HOPE-…-windows-portable.zip` | Descomprímelo y abre `hope.exe`. |
| iPhone / iPad (iOS 15 o superior) | `HOPE-…-ios-sin-firmar.ipa` | Apple solo permite instalar apps firmadas: fírmala e instálala con [AltStore](https://altstore.io) o [Sideloadly](https://sideloadly.io) usando tu Apple ID (con una cuenta gratuita la firma dura 7 días y hay que renovarla). Con una cuenta de pago de Apple Developer se puede distribuir por TestFlight o la App Store. |

## Qué hace (versión 0.3)

- **Silueta** de mujer u hombre, vista de frente y de espaldas, con 16 zonas: pies, pantorrillas, muslos, glúteos, perineo, abdomen, pecho, lumbar, espalda, hombros, brazos, manos, cuello (por delante y por detrás), cara y cabeza. Se marcan tocando el cuerpo o desde el botón «Zonas».
- **Lado izquierdo, derecho o ambos** en pies, pantorrillas, muslos, glúteos, hombros, brazos y manos. Los lados son siempre los del paciente; las letras **D** e **I** junto a la silueta lo recuerdan.
- **Dolor de fondo (0–10):** las zonas marcadas se colorean de transparente a rojo intenso y laten suavemente.
- **Eventos:** intensidad (0–10), frecuencia (10–500 por minuto, en escala logarítmica) y tipo (pinchazo, quemazón, rasgadura, arañazo, punzada, golpe). Cada tipo tiene su propia chispa animada.
- **Animación en bucle de 10 s**, idéntica cada vez que se reproduce un registro.
- **Registro** con fecha y hora automáticas, nota opcional y **histórico** con miniaturas animadas, filtro por fechas, edición, «usar como punto de partida», borrado con deshacer y registros atrasados.
- **Superficie afectada** estimada en % del cuerpo (cada lado cuenta la mitad de su zona).
- **Compartir un registro** como imagen con todos los eventos de un minuto, GIF animado del bucle o vídeo MP4 (con el codificador que ya incluyen Android, iOS y Windows; si un equipo no puede, se ofrece el GIF). Se puede ocultar la fecha.
- **Tratamientos:** lidocaína, fentanilo y oxicodona de partida, y los medicamentos que añadas. Vía, dosis, fecha (puntual o periodo), pauta, efectos adversos y notas.
- **Gráficas** de los cuatro parámetros en escala relativa común, por día, semana o mes (media de los registros; los huecos sin datos no se rellenan), con los tratamientos superpuestos, cursor con la silueta de ese momento, reproducción, vista por parámetro y tabla. Comparación de 7, 14 o 28 días antes y después de un tratamiento.
- **Alimentación** *(nuevo en 0.3)*: para cada día, lo que se comió por la **mañana** y por la **tarde**, elegido de una lista de alimentos básicos (pan, pasta, arroz, carne roja, carne blanca, pescado, grasa vegetal, azúcar…) a la que puedes añadir los tuyos. Historial por días con filtro por alimento y, desde cada día, una pantalla que muestra juntos **los alimentos del Día 1 y el dolor de fondo de los Días 1, 2, 3 y 4**, con su media, su máximo y la media de los 7 días anteriores como referencia. Muestra coincidencias en el tiempo, no causas.
- **Exportar** las gráficas como imagen PNG, GIF animado, Excel (resumen, registros y tratamientos) o informe PDF para la consulta.
- **Idiomas:** español e inglés (Ajustes → Apariencia → Idioma), también la lista de alimentos básicos. Los textos que escribes tú (notas, alimentos añadidos) se muestran tal cual.
- **Copia de seguridad** de todos los datos en un archivo JSON, para guardarla o pasarla a otro dispositivo.
- **Accesibilidad:** controles grandes con botones + / −, valores escribibles, lector de pantalla, atajos de teclado en Windows (R registrar, C compartir, H histórico, G gráficos, T tratamientos, A alimentación), tema claro/oscuro y modo «Reducir movimiento».
- **Privacidad:** todo se guarda solo en el dispositivo. Sin cuentas, servidores, publicidad ni analítica. La primera vez que compartes algo, HOPE te recuerda que son datos de salud.

Las estadísticas son solo descriptivas: HOPE no indica dosis ni valora si un tratamiento o un alimento influye en el dolor. Los cambios que se ven en las gráficas no demuestran que un tratamiento o un alimento sea la causa; coméntalos con tu equipo médico.

## Hoja de ruta

1. **Fase 1 – versión mínima** *(0.1)*: pantalla principal, animación, registro, histórico y ajustes. Android y Windows.
2. **Fase 2 – compartir y analizar** *(0.2)*: lateralidad, cuello, compartir imagen/GIF/MP4, tratamientos, gráficas, exportación a PNG, GIF, Excel y PDF, y copia de seguridad.
3. **Alimentación e iOS** *(0.3, esta versión)*: registro de la alimentación por la mañana y por la tarde, historial y relación con el dolor de los cuatro días siguientes, y app para iPhone y iPad.
4. **Fase 4 – pulido y publicación:** recordatorios, versión web instalable (PWA) y publicación en tiendas.

## Para desarrolladores

### Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (canal estable).
- Android: Android Studio o el SDK de Android y Java 17.
- Windows: Visual Studio 2022 con «Desarrollo para el escritorio con C++».
- iOS: un Mac con Xcode.

### Ejecutar

```bash
bash tool/preparar_plataformas.sh   # genera android/, ios/, windows/ y web/, y los iconos
flutter run                         # o flutter run -d windows
```

Las carpetas de plataforma no se guardan en el repositorio: se generan con el script anterior para que el proyecto sea más fácil de mantener.

### Pruebas

```bash
flutter analyze
flutter test                              # pruebas y archivos de muestra en build/muestras
python3 tool/validar_muestras.py build/muestras
bash tool/prueba_video.sh windows         # vídeo MP4 en un dispositivo (o emulator-5554)
```

En cada cambio, la compilación automática valida con herramientas estándar (Pillow, openpyxl, pypdf y FFmpeg) las imágenes, GIF, Excel, PDF y vídeos que genera la app, y prueba el vídeo MP4 en Windows y en un emulador de Android.

### Compilar

```bash
flutter build apk --release        # Android → build/app/outputs/flutter-apk/app-release.apk
flutter build windows --release    # Windows → build/windows/x64/runner/Release/
iscc /DMyAppVersion=0.2.0 installer\hope.iss   # instalador de Windows (Inno Setup 6)
flutter build ios --release        # iOS (en un Mac; para instalarla hace falta firmarla con un Apple ID)
flutter build ios --release --no-codesign   # iOS sin firmar, como en la compilación automática
```

**Compilación automática:** cada cambio en `main` ejecuta las pruebas y genera el APK, la app de iOS sin firmar (`.ipa`) y el instalador de Windows (pestaña *Actions*, sección *Artifacts*). El vídeo MP4 se prueba en Windows, en un emulador de Android y en un simulador de iPhone. Para publicar una versión descargable en *Releases*: pestaña *Actions* → «Compilar HOPE» → «Run workflow» → marcar «Publicar versión» (usa el número de `version` de `pubspec.yaml`).

**Firma de Android:** para que cada versión se pueda instalar encima de la anterior sin perder datos, todas deben firmarse con la misma clave. Guarda la clave (keystore con alias `androiddebugkey` y contraseñas `android`) codificada en base64 en el secreto del repositorio `ANDROID_KEYSTORE_BASE64`. Sin ese secreto, cada compilación usa una clave temporal.

### Estructura

```
lib/
  animation/   motor de la animación (chispas, pulso) y dibujo de la silueta
  charts/      agrupación por día/semana/mes, comparación antes/después, alimentación y dolor (días 1 a 4) y dibujo de las gráficas
  core/        configuración, geometría del cuerpo, generador aleatorio determinista
  data/        guardado local en archivos JSON y copia de seguridad
  export/      PNG, GIF (codificador propio), Excel, PDF, vídeo MP4 y compartir
  l10n/        textos en español e inglés
  models/      registro, tratamiento, alimentación y ajustes
  screens/     pantalla principal, histórico, reproductor, tratamientos, gráficos, alimentación y ajustes
  state/       estado de la app y de los controles
  widgets/     componentes reutilizables
packages/hope_media/   complemento propio de vídeo MP4 (MediaCodec en Android, AVFoundation en iOS, Media Foundation en Windows)
integration_test/      prueba del vídeo en un dispositivo
assets/config/
  hope_config.json     zonas, % de superficie, tipos de evento, colores y alimentos básicos (editable)
  body_geometry.json   siluetas (generadas con tool/gen_body.py)
tool/
  gen_body.py              genera la geometría y una vista previa: python3 tool/gen_body.py --preview vista.svg
  preparar_plataformas.sh  prepara las carpetas de plataforma (y las del complemento de vídeo)
  validar_muestras.py      comprueba los archivos exportados
  prueba_video.sh          prueba del vídeo MP4 en un dispositivo
installer/hope.iss         instalador de Windows (Inno Setup)
```

### Datos

Cada registro guarda: `id`, `fecha_hora` (ISO 8601 con zona horaria), `perfil_sexo`, `intensidad_dolor`, `zonas` (con el lado: `pies_izq`, `pies_der`…), `num_zonas`, `superficie_pct`, `intensidad_eventos`, `tipos_evento`, `frecuencia_eventos`, `semilla_animacion` y `nota`. Los tratamientos se guardan aparte (`hope_tratamientos.json`) con `medicamento`, `via`, `dosis`, `unidad`, `inicio`, `fin`, `pauta`, `efectos_adversos` y `notas`. La alimentación se guarda aparte (`hope_alimentacion.json`): los alimentos añadidos por el usuario o los básicos ocultos (`alimentos`, con `id`, `nombre` y `oculto`) y un registro por día (`dias`, con `fecha` en formato `AAAA-MM-DD`, `manana` y `tarde` con los identificadores de los alimentos). Los alimentos básicos se guardan por su clave (`bread`, `red_meat`…), así que cambian de idioma sin tocar los datos. El dolor de cada día se relaciona con la alimentación por la fecha local de cada registro. La copia de seguridad (`HOPE_copia_AAAA-MM-DD.json`, formato 3) reúne registros, tratamientos, medicamentos, alimentación y ajustes; las copias de versiones anteriores se pueden seguir importando (conservan la alimentación que haya en el dispositivo). Los porcentajes de superficie son orientativos, basados en la tabla de Lund-Browder para adultos.

### Añadir un idioma

Añade el código del idioma a `S.supported` en `lib/l10n/strings.dart` y una entrada con ese código en cada texto. Añade también los nombres de zonas, tipos de evento, medicamentos y alimentos en `assets/config/hope_config.json`. En iOS, añade el código a `CFBundleLocalizations` en `tool/preparar_plataformas.sh`.

### Añadir un alimento básico

Añade una entrada a `foods` en `assets/config/hope_config.json` con una clave nueva en minúsculas (`"id": "chocolate"`) y su nombre en cada idioma. No cambies ni reutilices la clave de un alimento existente: es lo que guardan los días ya registrados.

## Contribuir

Las sugerencias y mejoras son bienvenidas en la pestaña *Issues*. Si tienes dolor neuropático y quieres contar qué te ayudaría registrar, también es una gran contribución.

## Licencia

HOPE es software libre bajo la licencia **GNU GPL v3.0 o posterior** (ver [LICENSE](LICENSE)). Puedes usarlo, estudiarlo, modificarlo y compartirlo, siempre que las versiones derivadas sigan siendo libres bajo la misma licencia.
