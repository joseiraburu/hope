# Cambios

## 0.5.0

### Novedades
- **Pantalla de inicio con nueve cuadros** que ocupan toda la pantalla en una cuadrícula de 3 × 3, de izquierda a derecha y de arriba abajo: **Dolor, Alimentación, Sueño, Deposiciones, Medicación, Historial, Generar informe, Gráficos e Importar/Exportar**. Cada cuadro abre su sección y muestra una línea de estado si cabe (por ejemplo, «Sin evaluar hoy» o «Hoy: 2»). En Windows, las teclas 1 a 9 abren cada cuadro. Ajustes queda en el icono de la barra superior.
- **Botón «Inicio»** (icono de casa) en todas las secciones para volver a los cuadros. Si una pantalla tiene cambios sin guardar, pregunta antes de descartarlos.
- **Deposiciones** (cuadro, Ajustes o tecla D en Dolor): cada deposición con su **fecha y hora** (por defecto, la actual) y su **calidad de 1 a 5**, elegida con un solo toque: 1 estreñimiento total, 2 heces duras / con esfuerzo, 3 normal, 4 blandas y 5 diarrea líquida. Nota opcional. Lista de los últimos 30 días agrupada por día, con edición y borrado con deshacer. Puede haber varias el mismo día.
- **Historial** de todo en pestañas: Dolor (el histórico de siempre), Deposiciones, Sueño, Alimentación y Medicación, con el filtro de fechas común.
- **Gráficos** en dos pestañas: Dolor (la gráfica de siempre) y **Deposiciones**: calidad de cada deposición con la media del día y número de deposiciones por día, en 7, 14, 30 o 90 días, o en tabla.
- **Informe completo** (Generar informe): nuevo apartado **Deposiciones** con el total, la media diaria, la calidad media, cuántas de cada calidad, los días sin ninguna y los días con deposiciones duras (1–2) o blandas/líquidas (4–5), y una conclusión descriptiva. Solo aparece si se registran deposiciones. También va en el PDF y, si está activado, en el resumen para la IA.
- **Importar/Exportar**:
  - **Exportar informe completo**: un solo archivo `Hope_informe_AAAA-MM-DD.html` con todos los datos de todas las fechas (dolor, deposiciones, sueño, alimentación y medicación) y el resumen de los últimos 30 días. Se abre en cualquier navegador y se puede imprimir o guardar en PDF, así que se puede enviar al médico tal cual. Lleva dentro la copia de seguridad completa, de modo que el mismo archivo se carga en otro dispositivo. Se comparte con la hoja del sistema (correo, WhatsApp…) o, en el ordenador, con «Guardar como…».
  - **Importar**: acepta el informe `.html` y las copias `.json` de esta versión y de las anteriores. Comprueba el archivo antes de cargar nada, muestra lo que contiene y pregunta si **combinar** (añade lo nuevo sin duplicar) o **reemplazar** (con una confirmación más). Al terminar indica cuántos registros se han cargado.

### Cambios
- La app se abre en los cuadros; la antigua pantalla principal es ahora la sección **Dolor** (con los mismos controles, atajos y menú, que añade Deposiciones). La bienvenida de la primera vez aparece sobre los cuadros.
- «Histórico» pasa a llamarse **«Historial»**.
- «Evaluar el dolor» (tarjeta «Completa HOPE») abre la sección Dolor.
- La copia de seguridad pasa al **formato 5**: incluye las deposiciones. Las copias anteriores se siguen importando y conservan las deposiciones del dispositivo.
- «Borrar todos los datos» borra también las deposiciones.
- El texto de «Qué se envía» del análisis con IA menciona el número y la calidad de las deposiciones.
- La CI valida también el informe en HTML (`informe_completo.html`): que se lea como HTML y que su bloque de datos sea una copia de HOPE.

### Datos
- Nuevo archivo `hope_deposiciones.json` (`deposiciones`, con `id`, `fecha_hora`, `calidad` de 1 a 5, `nota` y `actualizado`). Los archivos de la 0.4 no cambian, así que no hace falta migrar nada: al instalar la 0.5 encima, todos los datos se conservan.
- Copia de seguridad formato 5: clave `deposiciones`. El informe HTML lleva la misma copia en `<script type="application/json" id="hope-datos">`.

### Decisiones tomadas
- **Un único archivo para el médico y para otro dispositivo:** HTML, porque cualquier móvil u ordenador lo abre sin instalar nada y puede llevar los datos dentro sin que se vean. El PDF del informe de 7, 14 o 30 días sigue en «Generar informe».
- **Combinar** nunca sobrescribe lo del dispositivo salvo que el archivo tenga una versión guardada más tarde: registros de dolor, tratamientos, medicamentos y alimentos con el mismo identificador se quedan como están; noches, días de comidas y deposiciones que estén en los dos se quedan con la versión más reciente. Los ajustes no cambian al combinar.
- El apartado Deposiciones del informe no exige un mínimo de registros: describe lo que haya (con pocas deposiciones, eso ya es un dato). Si hay deposiciones de otras fechas pero ninguna en el periodo, muestra «Datos insuficientes».
- Colores de la escala: marrones para las duras, verde para la normal y azules para las blandas y líquidas; el rojo sigue reservado para el dolor. El color siempre va con el número y el nombre.

## 0.4.0

### Novedades
- **Alimentación en cinco tomas:** desayuno, almuerzo, comida, merienda y cena, cada una con su desplegable de alimentos (selección múltiple, buscador y «Añadir alimento…»), su **hora** y la casilla **«No realizada»**. Al elegir alimentos hoy, la toma recibe la hora actual; en días pasados, la hora habitual de la toma. Se puede cambiar.
- Tarjeta **«Completa HOPE»** en Alimentación (hoy): muestra si ya se evaluó el dolor, si se registró el sueño de anoche y cuántas tomas faltan, con accesos directos a cada cosa.
- **Sueño** (menú ⋮, Ajustes o tecla S en Windows): calidad de cada noche de 1 (muy malo) a 5 (muy bueno), «Con dolor» / «Sin dolor» (opcional) y nota. Lista de noches con edición y borrado con deshacer.
- **Recordatorios «Completa HOPE»** (Ajustes → Recordatorios): cinco alarmas diarias, cada una con interruptor, hora y la toma que abre. Por defecto: 8:00, 11:00, 14:00, 17:30 y 21:00, apagadas. El permiso de notificaciones se pide al activar la primera, y si se deniega se explica qué pasa. En Android e iOS son avisos del sistema; en Windows y macOS, una ventana mientras HOPE está abierta. **Añadir al calendario** crea un `.ics` con las alarmas activas, repetidas cada día.
- **Informe completo** (menú ⋮, Ajustes o tecla I en Windows) de los últimos 7, 14 o 30 días: registros del periodo, evolución del dolor (media, mínimo y máximo, eventos, tendencia, mitades del periodo, zonas y tipos más frecuentes), sueño, alimentación y **relación con el dolor**: tras noches malas y buenas, correlación, noches con dolor, cada alimento el mismo día y el siguiente, y días con tomas saltadas. **«Datos insuficientes»** por apartados, con lo que falta. Conclusiones descriptivas y aviso «Este informe no sustituye la valoración de un profesional sanitario». Exportación a **PDF**.
- **Análisis con IA** opcional (Ajustes → Análisis con IA): desactivado por defecto, con consentimiento expreso y explicación de qué se envía. Usa cualquier servicio compatible con la API de chat de OpenAI (Groq, OpenRouter, Ollama en local...). Se envía solo el resumen agregado del informe; si el servicio falla, queda el análisis local.

### Cambios
- La copia de seguridad pasa al formato 4: incluye el sueño y las alarmas, y deja fuera la clave del servicio de IA. Las copias anteriores se siguen importando y conservan el sueño del dispositivo.
- «Borrar todos los datos» borra también el sueño.
- El texto de privacidad menciona el análisis opcional con IA.
- Android: permisos de notificaciones, alarmas exactas, arranque e internet; receptores de avisos programados, icono de notificación y «desugaring» de Java (`tool/preparar_plataformas.sh`).
- Compilación automática de Android con Java 21: Flutter 3.50 trae una versión de las herramientas de Android cuyo análisis «lint» no funciona con Java 17.
- El informe completo se valida en la CI como PDF (`informe_completo.pdf` y `informe_completo_insuficiente.pdf`).

### Datos
- `hope_alimentacion.json`: cada día guarda `comidas` (`desayuno`, `almuerzo`, `comida`, `merienda`, `cena`) con `alimentos`, `hora` y `no_realizada`. Los días de la 0.3 (`manana`, `tarde`) se leen como desayuno y comida.
- Nuevo archivo `hope_sueno.json` con las noches.
- `hope_ajustes.json`: `recordatorios`, `ia_activa`, `ia_url`, `ia_modelo` e `ia_clave`.

### Decisiones tomadas
- La noche se guarda con el día en que uno se levanta, para compararla con el dolor de ese día.
- El informe compara la media del dolor de fondo (0–10) entre grupos de días. Mínimos: 7 días con dolor, 5 noches, 7 días con comidas, 5 días con sueño y dolor, 7 días con comidas y dolor, y 3 días en cada grupo para comparar un alimento. Se señala una diferencia a partir de 1 punto. Los umbrales están en `lib/charts/full_report.dart`.
- Los avisos del sistema se programan uno a uno para los próximos 12 días (iOS admite 64 pendientes) y se renuevan al abrir HOPE; así respetan el cambio de hora.
- En Windows no se programan avisos del sistema: sin empaquetado MSIX no se pueden cancelar ni cambiar. Por eso HOPE avisa mientras está abierta y ofrece el calendario.

## 0.3.0

### Novedades
- Pestaña **Alimentación** (menú ⋮, Ajustes o tecla A en Windows) con dos vistas:
  - **Registrar:** desplegable del día (hoy, los 30 días anteriores u otra fecha; nunca días futuros) y dos desplegables de selección múltiple, **Mañana** y **Tarde**, con 23 alimentos básicos y buscador. «Añadir alimento…» crea un alimento nuevo, lo marca y lo deja en las dos listas para los días siguientes. Un registro por día: volver a un día lo carga para editarlo. Aviso si se cambia de día o se sale con cambios sin guardar.
  - **Historial:** días con comidas, del más reciente al más antiguo, con filtro por alimento. El detalle de cada día permite editarlo, borrarlo (con deshacer) y abrir la relación con el dolor.
- Pantalla **Alimentación y dolor:** alimentos del Día 1 y dolor de fondo de los Días 1 a 4 en una sola vista. Gráfica con la media y el máximo de cada día y la media de los 7 días anteriores como referencia; tarjetas con los registros de cada día (se abren en el reproductor), la diferencia con la media de referencia y, plegadas, las comidas de los días 2 a 4. Los días sin registros son huecos («Sin registro de dolor»), nunca cero; los días futuros se marcan «Aún no disponible». Se pasa de un día con comidas a otro con las flechas o deslizando.
- **Mis alimentos** (Ajustes → Alimentación): renombrar, ocultar y borrar alimentos. Los nombres repetidos se detectan sin tener en cuenta mayúsculas, tildes ni espacios y en los dos idiomas («pan», « PAN », «Bread»). Un alimento ya usado se oculta en lugar de borrarse.
- **iOS:** compilación para iPhone y iPad y vídeo MP4 con AVFoundation en el complemento `hope_media`. La app declara español e inglés a iOS (para que «Sistema» elija bien el idioma) y el permiso para guardar imágenes y vídeos en Fotos.
- Compilación automática de la app de iOS sin firmar (`.ipa`) y prueba del vídeo en un simulador de iPhone.

### Cambios
- La copia de seguridad pasa al formato 3 e incluye la alimentación. Las copias anteriores se siguen importando y conservan la alimentación del dispositivo.
- «Borrar todos los datos» borra también la alimentación.
- Desde la pantalla Alimentación y dolor, el reproductor de un registro no ofrece «Usar como punto de partida».

### Datos
- La alimentación se guarda en un archivo nuevo, `hope_alimentacion.json`. Los archivos de la versión 0.2 (`hope_registros.json`, `hope_tratamientos.json`, `hope_ajustes.json`) no cambian.
- Los alimentos básicos se guardan por su clave estable (`bread`, `red_meat`…) y los días como fecha local `AAAA-MM-DD`.

### Decisiones tomadas
- El inglés ya estaba disponible desde la 0.2 (Ajustes → Apariencia → Idioma: Sistema, Español o English). Se mantiene y se traduce todo lo nuevo.
- Como HOPE no tiene barra de pestañas, Alimentación se abre desde el menú ⋮ de la pantalla principal (junto a Tratamientos) y desde Ajustes; dentro tiene sus pestañas Registrar e Historial.
- Las listas de Mañana y Tarde son de selección múltiple, porque una comida suele tener varios alimentos.
- La gráfica usa el dolor de fondo (0–10). La media de referencia es la media de las medias diarias de los 7 días anteriores al Día 1, para que un día con muchos registros no pese más.
- La versión de iOS sale del mismo código Flutter que Android y Windows, no es una app aparte.

## 0.2.0
- Lateralidad (izquierda, derecha o ambos) y cuello por delante y por detrás.
- Compartir un registro como imagen, GIF o vídeo MP4.
- Tratamientos, gráficas con comparación antes/después y exportación a PNG, GIF, Excel y PDF.
- Copia de seguridad.

## 0.1.0
- Primera versión: pantalla principal, animación, registro, histórico y ajustes. Android y Windows.
