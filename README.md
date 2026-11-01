# Luma · Estudio creativo voxel

Demo estática con cinco personajes de bloques y plantitas: Luma, Elio, Iris, Milo y Alba.

## Novedades

- Texto más grande, mejor contraste y controles legibles.
- Cinco oficinas individuales con navegación, zoom y cámara desplazable.
- Sala de reuniones, café y tablero de referencias.
- Animación con piernas, brazos y gestos de trabajo, sin salto constante del cuerpo.
- Luma delega los encargos al equipo completo.
- Las entregas se abren al finalizar y conservan botones visibles para consultar y descargar sus archivos.
- Hasta tres referencias PNG, JPG o WebP por encargo; se guardan en el navegador y se pueden revisar en la entrega y en el tablero.

## Alcance de esta demo

No hay IA conectada en esta versión estática. Las fases y los resultados son muestras simuladas; no se interpreta el brief ni el estilo de las referencias con IA. Un recorrido completo dura aproximadamente 36 segundos. Los datos son locales al navegador, no se sincronizan entre dispositivos y los trabajos avanzan mientras la página esté abierta.

Para usar IA real se necesita el servidor del proyecto y una clave configurada allí. Esa integración permite enviar referencias visuales a los modelos; no debe configurarse ninguna clave en este HTML.

## Netlify

Importa la rama `demo-netlify`, deja vacío el comando de compilación y publica el directorio `.`. `netlify.toml` conserva esa configuración. Los nuevos commits a esta rama pueden activar el despliegue automático si el sitio está conectado a ella.

Esta rama contiene solo la demo compilada y autocontenida. El código fuente editable se conserva en el proyecto original del entorno. No incluye claves ni imágenes privadas de usuarios.
