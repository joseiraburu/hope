# HOPE 0.5.0: notas de entrega

Cambios pedidos en la especificación «Hope v5.0» (deposiciones, inicio en cuadros e Importar/Exportar), sobre el código de la 0.4.0.

## Cómo está hecha la app (resumen)

- App Flutter: un `AppController` global (`lib/state/app_controller.dart`) con los datos en memoria, y almacenes JSON locales, uno por sección (`lib/data/stores.dart`).
- Hasta la 0.4, la pantalla principal (`HomeScreen`) era la de dolor y el resto se abría desde su menú ⋮ o desde Ajustes.
- En la 0.5 se añade una pantalla de inicio (`StartScreen`) delante de todo. `HomeScreen` pasa a ser la sección **Dolor**, sin cambios en sus controles.

## Cambios por archivo

### Nuevos
| Archivo | Qué hace |
| --- | --- |
| `lib/models/bowel.dart` | Modelo `BowelEntry`: id, fecha y hora, calidad 1–5, nota y fecha de guardado. |
| `lib/screens/bowel_screen.dart` | Sección Deposiciones: fecha y hora (por defecto, ahora), calidad con un toque, nota, lista de 30 días por día, edición y borrado con deshacer. |
| `lib/screens/start_screen.dart` | Inicio: 9 cuadros en 3 × 3 a pantalla completa, con línea de estado y teclas 1–9. |
| `lib/screens/data_screen.dart` | Importar/Exportar: informe completo, importar y copia .json. |
| `lib/export/full_export_html.dart` | Genera el informe completo en HTML (legible + datos dentro). |
| `lib/data/merge.dart` | Combinar un archivo con los datos del dispositivo sin duplicar (`mergeBackup`) y recuentos (`DataCounts`). |
| `lib/charts/bowel_stats.dart` | Deposiciones por día y resumen, para las gráficas. |
| `lib/widgets/bowel_chart.dart` | Pestaña Deposiciones de Gráficos: calidad + media del día y número por día, o tabla. |
| `lib/widgets/bowel_style.dart` | Colores de la escala y círculo con el número. |
| `lib/widgets/home_action.dart` | Botón «Inicio» y `goHome()`, que respeta los cambios sin guardar. |
| `lib/widgets/welcome.dart` | Bienvenida de la primera vez (antes estaba dentro de `HomeScreen`). |
| `test/bowel_test.dart`, `test/import_export_test.dart`, `test/start_screen_test.dart` | Pruebas nuevas. |

### Modificados
| Archivo | Cambio |
| --- | --- |
| `lib/app.dart` | La app arranca en `StartScreen`. |
| `lib/main.dart` | Crea el almacén `hope_deposiciones.json`. |
| `lib/state/app_controller.dart` | Estado de deposiciones (`saveBowel`, `deleteBowel`, `restoreBowel`, `bowelOn`…), incluidas en `deleteAll` y `replaceAll`. |
| `lib/data/stores.dart` | `BowelStore`, `MemoryBowelStore` y `JsonFileBowelStore`. |
| `lib/data/backup.dart` | Copia formato 5 con `deposiciones`; lee el JSON dentro del HTML (`decodeExportFile`); guarda versión y fecha de la copia. |
| `lib/export/backup_flow.dart` | `exportFullReport` (HTML); `importBackup` nuevo: valida, enseña el contenido, combinar o reemplazar, confirmación y resultado. |
| `lib/charts/full_report.dart` | Apartado `BowelSection` en el informe completo. |
| `lib/charts/full_report_text.dart` | Textos del apartado Deposiciones, línea de cobertura y conclusión. |
| `lib/screens/home_screen.dart` | Botón Inicio, parámetro `startFrom`, Deposiciones en el menú y tecla D; la bienvenida sale de aquí. |
| `lib/screens/history_screen.dart` | Historial en 5 pestañas (Dolor, Deposiciones, Sueño, Alimentación, Medicación) con el filtro de fechas común. |
| `lib/screens/charts_screen.dart` | Pestañas Dolor / Deposiciones. |
| `lib/screens/food_screen.dart` | Botón Inicio, `initialDay` y «Evaluar el dolor» abre la sección Dolor. |
| `lib/screens/sleep_screen.dart`, `treatments_screen.dart`, `report_screen.dart`, `settings_screen.dart` | Botón Inicio; el informe recibe las deposiciones; Ajustes enlaza a Deposiciones e Importar/Exportar. |
| `lib/l10n/strings.dart` | Textos nuevos en español e inglés; «Histórico» → «Historial». |
| `lib/core/version.dart`, `pubspec.yaml` | Versión 0.5.0 (+5). |
| `tool/validar_muestras.py` | La CI valida el informe HTML de muestra. |
| `test/*` (widget, capturas, daily_screens, food_screen, treatments, sleep, helpers) | Adaptadas a que la app arranque en los cuadros; capturas nuevas. |
| `README.md`, `CHANGELOG.md`, `docs/notas-version.md` | Documentación de la 0.5. |

## Supuestos y decisiones

1. **Versión 0.5.0**, no 5.0.0: la anterior era la 0.4.0. Si se quiere 5.0.0, se cambia en `pubspec.yaml` y en `lib/core/version.dart`.
2. **Escala de deposiciones:** el 1 y el 5 son los de la especificación. Los textos del 2 al 4 («Heces duras / con esfuerzo», «Normal», «Blandas») están en `lib/l10n/strings.dart` (`bowelQualityName`).
3. **Un solo archivo para los dos usos: HTML.** Lo abre cualquier navegador (y se puede imprimir o guardar en PDF desde él) y lleva dentro la copia completa en JSON sin que se vea. El PDF sigue disponible en «Generar informe» para 7, 14 o 30 días.
4. **Combinar:** lo del dispositivo no se sobrescribe. La excepción son noches, días de comidas o deposiciones que estén en los dos sitios y que en el archivo se guardaran más tarde. Al combinar, los ajustes no cambian. **Reemplazar** pide una confirmación más y carga también los ajustes, salvo la clave de la IA, igual que antes.
5. **Barra superior en el inicio:** una barra fina con el logo y el botón de Ajustes encima de los cuadros. Sin ella no habría forma de llegar a Ajustes.
6. **Secciones que no existían:** Deposiciones e Importar/Exportar son nuevas. «Medicación» abre Tratamientos. El Historial antes solo era de dolor y ahora tiene pestañas.
7. **No hace falta migrar datos:** las deposiciones van en un archivo nuevo y los archivos de la 0.4 no cambian.
8. **Informe:** el apartado Deposiciones solo aparece si alguna vez se ha registrado una, para no añadir un bloque vacío a quien no las usa.

## Puntos que necesitan tu decisión

- Los textos de las calidades 2 a 4.
- La versión: 0.5.0 o 5.0.0.

## Cómo probarlo

1. `flutter analyze` y `flutter test`, o subir a GitHub y lanzar «Compilar HOPE» en Actions. Las capturas `00_…`, `50_…` a `56_…` y la muestra `informe_completo.html` quedan en los artefactos.
2. **Inicio:** al abrir salen los 9 cuadros en orden. Gira el móvil: siguen en 3 × 3.
3. **Deposición:** Deposiciones → toca «5 · Diarrea líquida» → Guardar. Aparece en la lista de hoy, en Historial → Deposiciones y en Gráficos → Deposiciones.
4. **Cada sección:** entra desde su cuadro y vuelve con el botón de la casa (o con Atrás).
5. **Exportar en un dispositivo:** Importar/Exportar → Exportar y compartir → envíatelo por correo. Ábrelo en el ordenador: se lee como informe.
6. **Importar en otro dispositivo:** Importar/Exportar → Elegir archivo… → ese `.html`. Debe mostrar lo que contiene y dejarte elegir Combinar o Reemplazar. Al terminar dice cuántos registros ha cargado. Si lo combinas dos veces, la segunda debe decir que no había nada nuevo.
7. **Copia antigua:** importa una copia `.json` de la 0.4. Debe cargarse y conservar las deposiciones del dispositivo.
