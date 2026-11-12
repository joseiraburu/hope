# Cambios

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
