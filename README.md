<p align="center">
  <img src="assets/icon/logo-ovalo.svg" alt="Logo de HOPE" height="140">
</p>

# HOPE

**HOPE** es una app gratuita y de código abierto para registrar y **mostrar** el dolor neuropático crónico: dónde duele, con qué intensidad y cómo son los pinchazos, quemazones o punzadas. Convierte cada estado en una animación en bucle que se puede guardar en un histórico y, en próximas versiones, compartir como vídeo con el médico, la familia o las amistades.

Nace de la experiencia de una persona que lleva 15 años con una neuropatía sensitiva de fibra fina idiopática, con el deseo de ayudar a cualquiera que viva algo parecido.

> HOPE es una herramienta de registro personal. **No es un producto sanitario**: no diagnostica, no recomienda tratamientos y no sustituye la consulta con profesionales sanitarios.

## Descargar e instalar

Las versiones listas para instalar están en la pestaña **[Releases](https://github.com/joseiraburu/hope/releases)**.

| Sistema | Archivo | Cómo instalarlo |
| --- | --- | --- |
| Android 8 o superior | `HOPE-…-android.apk` | Ábrelo en el móvil. Si lo pide, permite «Instalar aplicaciones de origen desconocido». |
| Windows 10/11 | `HOPE-…-windows-instalador.exe` | Ejecútalo. Si aparece «Windows protegió su PC», pulsa «Más información» → «Ejecutar de todas formas». |
| Windows (sin instalar) | `HOPE-…-windows-portable.zip` | Descomprímelo y abre `hope.exe`. |
| iPhone / iPad | — | Pendiente (fase 3, como versión web instalable). |

## Qué hace (fase 1)

- **Silueta** de mujer u hombre, vista de frente y de espaldas, con 14 zonas: pies, pantorrillas, muslos, glúteos, perineo, abdomen, pecho, lumbar, espalda, hombros, brazos, manos, cara y cabeza. Se marcan tocando el cuerpo o desde el botón «Zonas».
- **Dolor de fondo (0–10):** las zonas marcadas se colorean de transparente a rojo intenso y laten suavemente.
- **Eventos:** intensidad (0–10), frecuencia (10–500 por minuto, en escala logarítmica) y tipo (pinchazo, quemazón, rasgadura, arañazo, punzada, golpe). Cada tipo tiene su propia chispa animada.
- **Animación en bucle de 10 s**, idéntica cada vez que se reproduce un registro.
- **Registro** con fecha y hora automáticas, nota opcional y **histórico** con miniaturas animadas, filtro por fechas, edición, «usar como punto de partida», borrado con deshacer y registros atrasados.
- **Superficie afectada** estimada en % del cuerpo.
- **Accesibilidad:** controles grandes con botones + / −, valores escribibles, lector de pantalla, atajos de teclado en Windows (R registrar, H histórico, E vídeo), tema claro/oscuro y modo «Reducir movimiento».
- **Privacidad:** todo se guarda solo en el dispositivo. Sin cuentas, servidores, publicidad ni analítica.

## Hoja de ruta

1. **Fase 1 – versión mínima** *(esta versión)*: pantalla principal, animación, registro, histórico y ajustes. Android y Windows.
2. **Fase 2 – compartir y analizar:** exportar vídeo MP4 para WhatsApp y correo, gráficas de los cuatro parámetros, copia de seguridad y CSV, compilación para iOS.
3. **Fase 3 – pulido y publicación:** informe PDF para el médico, recordatorios, versión web instalable (PWA) y publicación en tiendas.

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
flutter test
```

### Compilar

```bash
flutter build apk --release        # Android → build/app/outputs/flutter-apk/app-release.apk
flutter build windows --release    # Windows → build/windows/x64/runner/Release/
iscc /DMyAppVersion=0.1.0 installer\hope.iss   # instalador de Windows (Inno Setup 6)
flutter build ios --release        # iOS (en un Mac, con cuenta de Apple Developer)
```

**Compilación automática:** cada cambio en `main` ejecuta las pruebas y genera el APK y el instalador de Windows (pestaña *Actions*, sección *Artifacts*). Al crear una etiqueta `vX.Y.Z` se publica una versión descargable en *Releases*.

**Firma de Android:** para que cada versión se pueda instalar encima de la anterior sin perder datos, todas deben firmarse con la misma clave. Guarda la clave (keystore con alias `androiddebugkey` y contraseñas `android`) codificada en base64 en el secreto del repositorio `ANDROID_KEYSTORE_BASE64`. Sin ese secreto, cada compilación usa una clave temporal.

### Estructura

```
lib/
  animation/   motor de la animación (chispas, pulso) y dibujo de la silueta
  core/        configuración, geometría del cuerpo, generador aleatorio determinista
  data/        guardado local en archivos JSON
  l10n/        textos en español e inglés
  models/      registro y ajustes
  screens/     pantalla principal, histórico, reproductor y ajustes
  state/       estado de la app y de los controles
  widgets/     componentes reutilizables
assets/config/
  hope_config.json     zonas, % de superficie, tipos de evento y colores (editable)
  body_geometry.json   siluetas (generadas con tool/gen_body.py)
tool/
  gen_body.py              genera la geometría y una vista previa: python3 tool/gen_body.py --preview vista.svg
  preparar_plataformas.sh  prepara las carpetas de plataforma
installer/hope.iss         instalador de Windows (Inno Setup)
```

### Datos

Cada registro guarda: `id`, `fecha_hora` (ISO 8601 con zona horaria), `perfil_sexo`, `intensidad_dolor`, `zonas`, `num_zonas`, `superficie_pct`, `intensidad_eventos`, `tipos_evento`, `frecuencia_eventos`, `semilla_animacion`, `nota` y `video_ruta`. Los porcentajes de superficie son orientativos, basados en la tabla de Lund-Browder para adultos.

### Añadir un idioma

Añade el código del idioma a `S.supported` en `lib/l10n/strings.dart` y una entrada con ese código en cada texto. Añade también los nombres de zonas y tipos de evento en `assets/config/hope_config.json`.

## Contribuir

Las sugerencias y mejoras son bienvenidas en la pestaña *Issues*. Si tienes dolor neuropático y quieres contar qué te ayudaría registrar, también es una gran contribución.

## Licencia

HOPE es software libre bajo la licencia **GNU GPL v3.0 o posterior** (ver [LICENSE](LICENSE)). Puedes usarlo, estudiarlo, modificarlo y compartirlo, siempre que las versiones derivadas sigan siendo libres bajo la misma licencia.
