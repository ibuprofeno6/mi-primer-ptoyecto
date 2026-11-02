# TV Turbo · que tu smart TV vieja vaya más rápido

Una tele de hace unos años casi nunca va lenta porque "ya esté vieja". Va lenta porque carga apps de fábrica que nadie usa, servicios que analizan lo que ves para venderte publicidad, cachés llenas y animaciones pensadas para equipos más potentes. Todo eso se puede quitar. Lo que no se puede es aumentarle la memoria o cambiarle el procesador, así que el objetivo es realista: menús más ágiles, apps que abren antes y menos tirones.

Cuánto se puede hacer depende del sistema de tu tele.

## 1. ¿Qué sistema tiene tu tele?

| Si tu tele es… | Sistema | Qué se puede hacer |
|---|---|---|
| Sony, Philips, TCL, Sharp, Xiaomi, Motorola, Nokia, Hisense (algunos), o en la pantalla de inicio dice **Google TV** o tiene **Play Store** | Android TV / Google TV | Todo: TV Turbo (sección 3) + ajustes generales |
| Toshiba, Insignia y otras con **Fire TV** integrado | Fire OS (basado en Android) | TV Turbo parcial: diagnóstico, animaciones y limpieza |
| Samsung | Tizen | Ajustes manuales (sección 4) |
| LG | webOS | Ajustes manuales (sección 5) |
| TCL, Hisense o Sharp con **Roku** | Roku OS | Ajustes manuales (sección 6) |
| Hisense con VIDAA, Vizio y otras | Sistemas propios | Ajustes generales (sección 2) |

Si dudas, busca en Ajustes > Información (o Acerca de): ahí aparecen el modelo y la versión del sistema.

## 2. Lo que sirve en cualquier tele

Esto toma diez minutos y en muchas teles ya se nota.

1. **Reinicio de verdad.** Apagar con el control solo la pone en espera; hay teles que llevan semanas sin reiniciarse. Desconéctala de la corriente un minuto completo y vuelve a conectarla.
2. **Actualiza el software** desde Ajustes. Las actualizaciones suelen traer correcciones de rendimiento.
3. **Libera espacio.** Desinstala las apps que no uses. Con menos de 1 GB libre, el sistema se arrastra.
4. **Apaga el reconocimiento de contenido (ACR).** Es un servicio que analiza lo que aparece en pantalla para hacer publicidad dirigida; trabaja todo el tiempo en segundo plano. Según la marca se llama:
   - Samsung: *Servicios de información de visualización*
   - LG: *Live Plus* e *Información de visualización*
   - Roku TV: *Usar información de las entradas de TV*
   - Vizio: *Datos de visualización*
   - Sony (algunos modelos): *Samba Interactive TV*
   - Android TV en general: *Uso y diagnóstico* (Ajustes > Preferencias del dispositivo)
5. **Red.** Si las apps cargan lento, prueba con cable de red o acerca el router. Muchas veces la tele no es la lenta, es el Wi-Fi.

**Extra, para que también se vea mejor:** en películas y series desactiva el suavizado de movimiento (Motion, TruMotion, Auto Motion Plus, MotionFlow) y usa el modo de imagen Cine, Filmmaker o Calibrado. Con consola, activa el Modo juego.

## 3. Android TV / Google TV: TV Turbo

TV Turbo es un pequeño programa que corres desde tu computadora. Se conecta a la tele por la red de tu casa con `adb`, la herramienta oficial de Google para equipos Android. No necesita root, no instala nada en la tele, y **todo lo que cambia se puede deshacer** con una opción del menú.

### Qué hace cada opción

| Opción | Qué hace | ¿Cambia algo? |
|---|---|---|
| 1. Diagnóstico | Muestra modelo, memoria, espacio, qué apps gastan más y cuáles sobran. Lo guarda en un archivo. | No |
| 2. Optimización segura | Acelera las animaciones al doble, apaga búsquedas de Wi-Fi/Bluetooth en segundo plano, desactiva el Modo ambiente y apps de fábrica inútiles (Play Juegos, comentarios, impresión), limpia la caché. | Sí, reversible |
| 3. Quitar apps que no uso | Te muestra apps opcionales (Chromecast integrado, YouTube Music, Prime Video…) y quitas solo las que elijas. | Sí, reversible |
| 4. Optimizar el arranque de apps | Prepara el código de todas las apps para que abran más rápido. Tarda 5-20 min. Android 7 o más nuevo. | Solo optimiza |
| 5. Reiniciar la tele | Reinicio completo. | No |
| 6. Deshacer todo | Reactiva todo lo que TV Turbo desactivó y regresa los ajustes originales. | Revierte |

"Desactivar" no es borrar: la app queda en la tele, solo deja de ejecutarse. Por eso se puede devolver tal cual.

### Paso 1. Activa el modo desarrollador en la tele

1. Ve a **Ajustes > Preferencias del dispositivo > Información** (en Google TV: **Ajustes > Sistema > Información**).
2. Baja hasta **Compilación** (o *Compilación del SO de Android TV*) y pulsa OK siete veces seguidas, hasta que diga que ya eres desarrollador.
3. Regresa a Preferencias del dispositivo (o Sistema) y entra en **Opciones de desarrollador**.
4. Activa **Depuración por USB**. Aunque diga USB, en la mayoría de las teles también permite la conexión por red. Si tu tele tiene **Depuración inalámbrica** (Google TV con Android 11 o más nuevo), activa esa.

En Fire TV: **Configuración > Mi Fire TV > Acerca de**, pulsa siete veces sobre el nombre del dispositivo, y luego en **Opciones para desarrolladores** activa **Depuración ADB**.

### Paso 2. Anota la IP de la tele

**Ajustes > Red e Internet >** tu red. Busca *Dirección IP*; algo como `192.168.1.50`.

### Paso 3. Baja TV Turbo a tu computadora

La computadora tiene que estar en la misma red Wi-Fi que la tele. Descarga esta carpeta `smart-tv` (en GitHub: *Code > Download ZIP*, en la rama donde esté) y descomprímela. En Windows, clic derecho en el ZIP > *Extraer todo*; no lo abras desde dentro del ZIP.

### Paso 4. Ábrelo

- **Windows 10 u 11:** doble clic en `TV-Turbo.bat`. Si sale "Windows protegió su PC", pulsa *Más información > Ejecutar de todas formas*.
- **Mac:** abre la app Terminal, escribe `bash ` (con un espacio), arrastra el archivo `tv-turbo.sh` a la ventana y pulsa Enter.
- **Linux:** `bash tv-turbo.sh` dentro de la carpeta.

La primera vez te ofrece descargar `adb` desde el sitio oficial de Google (unos 15 MB). Luego te pide la IP y en la tele aparece un aviso de *¿Permitir depuración?*: marca *Permitir siempre desde esta computadora* y acepta.

Si tu tele usa Depuración inalámbrica, elige *Emparejar con código* al inicio y escribe la IP:PUERTO y el código que aparecen en la tele al pulsar *Vincular dispositivo con código*.

### Paso 5. El orden que recomiendo

1 (Diagnóstico) → 2 (Optimización segura) → 3 (solo si hay apps que de verdad no usas) → 4 → 5 (Reiniciar).

Al final, vuelve a Opciones de desarrollador en la tele y apaga la depuración. No es peligroso dejarla, pero tampoco hace falta.

### Si algo no te gusta

Opción **6, Deshacer todo**. Además, TV Turbo guarda en la carpeta `respaldo/` de tu computadora la lista de lo que desactivó. Un restablecimiento de fábrica de la tele también lo revierte todo.

### Lo que más se nota y TV Turbo no hace por ti: cambiar la pantalla de inicio

En las Android TV de hace unos años, la pantalla de inicio de fábrica, con sus filas de recomendaciones, es de lo más pesado que corre. Un launcher ligero como **Projectivy Launcher** o **FLauncher** (ambos en Play Store) la sustituye y la diferencia se nota desde que prendes la tele. Sigue las instrucciones de la app para que el botón Inicio la abra. TV Turbo no desactiva el launcher de fábrica a propósito: si eso se hace mal, la tele puede arrancar en una pantalla negra.

### Diagnóstico a la medida

El diagnóstico incluye una lista de apps del fabricante (Sony, TCL, Philips…). Esas no se tocan a ciegas porque algunas manejan la imagen, el sintonizador o el control. Si pegas el archivo `diagnostico-….txt` en una conversación con Claude, te dice cuáles de tu modelo se pueden quitar, y las quitas desde la opción 3 escribiendo su nombre.

## 4. Samsung (Tizen)

Samsung no permite instalar herramientas como TV Turbo, pero sus propios ajustes ayudan bastante:

- **Ajustes > Soporte > Cuidado del dispositivo > Iniciar cuidado del dispositivo** (en modelos de aproximadamente 2020 en adelante). Ahí mismo, en *Administrar almacenamiento*, puedes borrar la caché app por app.
- **Ajustes > Soporte > Términos y privacidad:** desactiva *Servicios de información de visualización* y *Publicidad basada en intereses*.
- **Ajustes > General > Funciones de Smart:** desactiva la ejecución automática de Smart Hub y de la última app usada.
- Si sigue lenta: **Ajustes > Soporte > Autodiagnóstico > Restablecer Smart Hub** (el PIN de fábrica suele ser 0000). Tendrás que volver a iniciar sesión en tus apps.

Los nombres cambian un poco según el año del modelo.

## 5. LG (webOS)

- **Ajustes > General:** busca *Live Plus* y desactívalo.
- **Ajustes > General > Acuerdos de usuario:** retira la aceptación de los acuerdos sobre información de visualización y publicidad.
- Activa **Encendido rápido+** (Quick Start+): la tele prende en segundos a cambio de gastar un poco más en espera.
- Para desinstalar apps, deja presionado OK sobre el ícono y elige eliminar.

Existe una comunidad (webOS Homebrew) que consigue acceso root en ciertas versiones de firmware y permite optimizaciones más profundas. Depende del modelo y la versión exactos, y no es un primer paso que recomiende.

## 6. Roku TV

- **Borrar caché:** en el control pulsa Inicio 5 veces, Arriba 1 vez, Retroceder 2 veces y Avanzar 2 veces. La tele se reinicia sola.
- **Ajustes > Privacidad > Experiencia de Smart TV:** desactiva *Usar información de las entradas de TV*.
- Elimina los canales que no uses.

## 7. Cuándo ya no vale la pena

Si tu tele tiene 1 GB de RAM o menos, Android 7 o anterior, o tus apps ya no se actualizan, ninguna optimización la va a dejar fluida con las apps de hoy. Ahí lo que conviene es un dispositivo de streaming por HDMI (Google TV Streamer, Fire TV Stick, Roku, etc.): la tele queda como pantalla, que es lo que mejor sigue haciendo, y cuesta mucho menos que una tele nueva. El diagnóstico de TV Turbo te dice cuánta memoria tiene la tuya.

## Archivos

| Archivo | Para qué |
|---|---|
| `TV-Turbo.bat` | Abre TV Turbo en Windows (doble clic) |
| `tv-turbo.ps1` | El programa para Windows |
| `tv-turbo.sh` | El programa para Mac y Linux |
| `tv/tvturbo.sh` | Lo que se ejecuta dentro de la tele. Guarda en `/data/local/tmp/tvturbo/` qué desactivó y los valores originales de cada ajuste |
