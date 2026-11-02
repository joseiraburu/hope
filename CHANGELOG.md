# Cambios

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
