#!/system/bin/sh
# TV Turbo: se ejecuta DENTRO de la tele (Android TV / Google TV / Fire TV) por adb.
# No necesita root. Todo lo que cambia queda anotado y se deshace con: sh tvturbo.sh restaurar
#
# Uso: sh tvturbo.sh diagnostico | optimizar | opcionales | desactivar PAQ... |
#                    reactivar PAQ... | compilar | restaurar

DIR="${TVTURBO_DIR:-/data/local/tmp/tvturbo}"
DESACTIVADAS="$DIR/desactivadas.txt"
AJUSTES="$DIR/ajustes-originales.txt"

mkdir -p "$DIR"
touch "$DESACTIVADAS" "$AJUSTES"

# Paquetes que no hacen falta en ninguna tele y se pueden quitar sin miedo.
SEGURAS='com.google.android.backdrop|Modo ambiente (salvapantallas con fotos: gasta memoria e internet)
com.google.android.feedback|Agente de comentarios de Google
com.google.android.play.games|Google Play Juegos
com.google.android.music|Google Play Música (el servicio ya no existe)
com.android.printspooler|Servicio de impresión'

# Útiles para algunas personas: solo se quitan si tú las eliges.
OPCIONALES='com.google.android.apps.mediashell|Chromecast integrado (quítalo solo si nunca envías videos desde el celular)
com.google.android.youtube.tvmusic|YouTube Music
com.google.android.youtube.tvkids|YouTube Kids
com.google.android.videos|Google Play Películas
com.amazon.amazonvideo.livingroom|Prime Video
com.spotify.tv.android|Spotify
com.google.android.tv.remote.service|Control remoto desde el celular (app Google TV)
com.google.android.marvin.talkback|TalkBack (lector de pantalla; déjalo si alguien lo usa)'

# Marcas de fabricantes, para listar sus apps en el diagnóstico (solo se listan, no se tocan).
FABRICANTES='sony|tcl|hisense|philips|tpvision|tpv\.|xiaomi|mitv|sharp|skyworth|panasonic|toshiba|vestel|jvc|haier|nokia|onn\.|walmart'

sdk=$(getprop ro.build.version.sdk)
[ -n "$sdk" ] || sdk=0

instalada() { pm path "$1" 2>/dev/null | grep -q '^package:'; }
habilitada() { pm list packages -e 2>/dev/null | grep -qx "package:$1"; }

espacio() { { df -h /data 2>/dev/null || df /data 2>/dev/null; } | tail -n 1 | sed 's/^/    /'; }
kb_a_mb() { echo $(( ${1:-0} / 1024 )); }
memoria() { sed -n "s/^$1: *\([0-9]*\) kB.*/\1/p" /proc/meminfo; }

ajuste() { # ajuste TABLA CLAVE VALOR -> guarda el valor original la primera vez
  if ! grep -q "^$1 $2 " "$AJUSTES"; then
    echo "$1 $2 $(settings get "$1" "$2")" >> "$AJUSTES"
  fi
  settings put "$1" "$2" "$3"
}

desactivar_uno() {
  if ! instalada "$1"; then echo "  [--] $1 no está instalada"; return; fi
  if ! habilitada "$1"; then echo "  [==] $1 ya estaba desactivada"; return; fi
  salida=$(pm disable-user --user 0 "$1" 2>&1)
  case "$salida" in
    *disabled-user*)
      grep -qx "$1" "$DESACTIVADAS" || echo "$1" >> "$DESACTIVADAS"
      echo "  [ok] $1 desactivada" ;;
    *)
      echo "  [x]  $1: el fabricante no deja desactivarla (no pasa nada)" ;;
  esac
}

reactivar_uno() {
  salida=$(pm enable "$1" 2>&1)
  case "$salida" in
    *"state: enabled"*) echo "  [ok] $1 reactivada" ;;
    *) echo "  [x]  $1: no se pudo reactivar ($salida)" ;;
  esac
  grep -vx "$1" "$DESACTIVADAS" > "$DESACTIVADAS.tmp"
  mv "$DESACTIVADAS.tmp" "$DESACTIVADAS"
}

titulo() { echo; echo "== $1"; }

diagnostico() {
  echo "TV TURBO · DIAGNÓSTICO"
  titulo "Equipo"
  echo "Marca y modelo:   $(getprop ro.product.manufacturer) $(getprop ro.product.model)"
  echo "Android:          $(getprop ro.build.version.release) (API $sdk)"
  echo "Firmware:         $(getprop ro.build.display.id)"
  echo "Encendida desde:  $(uptime 2>/dev/null | sed 's/^ *//')"

  titulo "Memoria RAM"
  total=$(memoria MemTotal)
  libre=$(memoria MemAvailable)
  [ -n "$libre" ] || libre=$(( $(memoria MemFree) + $(memoria Cached) ))
  echo "Total:            $(kb_a_mb "$total") MB"
  echo "Disponible ahora: $(kb_a_mb "$libre") MB"
  if [ "${total:-0}" -lt 1600000 ]; then
    echo "Nota: con menos de 1.5 GB de RAM cada app de fondo cuenta; vale la pena quitar lo que no uses."
  fi

  titulo "Almacenamiento interno"
  df -h /data 2>/dev/null || df /data

  titulo "Pantalla de inicio (launcher)"
  if [ "$sdk" -ge 24 ]; then
    cmd package resolve-activity --brief -a android.intent.action.MAIN \
      -c android.intent.category.HOME 2>/dev/null | tail -n 1
  else
    echo "(no disponible en esta versión de Android)"
  fi

  titulo "Animaciones (1 = normal, 0.5 = el doble de rápido)"
  for clave in window_animation_scale transition_animation_scale animator_duration_scale; do
    echo "$clave: $(settings get global "$clave")"
  done

  titulo "Apps"
  echo "Activas:          $(pm list packages -e 2>/dev/null | grep -c '^package:')"
  echo "Instaladas por ti o de fábrica como app normal: $(pm list packages -3 2>/dev/null | grep -c '^package:')"
  echo "Desactivadas:     $(pm list packages -d 2>/dev/null | grep -c '^package:')"
  echo "Desactivadas por TV Turbo: $(grep -c . "$DESACTIVADAS")"

  titulo "Las 12 apps que más memoria usan ahora"
  dumpsys meminfo 2>/dev/null \
    | sed -n '/Total [PR]SS by process/,/by OOM adjustment/p' \
    | sed '1d;$d' | head -n 12

  titulo "Apps de fábrica que se pueden quitar sin riesgo (presentes y activas)"
  lista_presentes "$SEGURAS" | sed 's/^/  /;s/|/  ->  /' | grep . || echo "  ninguna"

  titulo "Apps opcionales (solo si no las usas)"
  lista_presentes "$OPCIONALES" | sed 's/^/  /;s/|/  ->  /' | grep . || echo "  ninguna"

  titulo "Apps del fabricante (NO quitar a ciegas: pásale esta lista a Claude)"
  pm list packages -e -s 2>/dev/null | sed 's/^package://' \
    | grep -iE "$FABRICANTES" | sort | sed 's/^/  /' | grep . || echo "  ninguna detectada"

  titulo "Apps instaladas como app normal"
  pm list packages -3 2>/dev/null | sed 's/^package:/  /' | sort
}

lista_presentes() { # imprime "paquete|descripción" de las que están instaladas y activas
  activas=$(pm list packages -e 2>/dev/null)
  echo "$1" | while IFS='|' read -r paq desc; do
    [ -n "$paq" ] || continue
    echo "$activas" | grep -qx "package:$paq" && echo "$paq|$desc"
  done
}

optimizar() {
  echo "TV TURBO · OPTIMIZACIÓN SEGURA"
  antes=$(memoria MemAvailable)

  titulo "1/4 Animaciones al doble de velocidad"
  for clave in window_animation_scale transition_animation_scale animator_duration_scale; do
    ajuste global "$clave" 0.5
  done
  echo "  [ok] los menús se sentirán más ágiles"

  titulo "2/4 Búsquedas de Wi-Fi y Bluetooth en segundo plano"
  ajuste global wifi_scan_always_enabled 0
  ajuste global ble_scan_always_enabled 0
  echo "  [ok] apagadas (el Wi-Fi y el control Bluetooth siguen funcionando igual)"

  titulo "3/4 Apps de fábrica que no hacen falta"
  echo "$SEGURAS" | while IFS='|' read -r paq desc; do
    [ -n "$paq" ] && desactivar_uno "$paq"
  done
  # Si el salvapantallas era el Modo ambiente que acabamos de quitar, ponemos el de colores.
  if settings get secure screensaver_components | grep -q backdrop \
     && ! habilitada com.google.android.backdrop && instalada com.android.dreams.basic; then
    ajuste secure screensaver_components com.android.dreams.basic/com.android.dreams.basic.Colors
    echo "  [ok] salvapantallas cambiado a 'Colores' (más ligero)"
  fi

  titulo "4/4 Limpieza de caché"
  echo "  Antes:"
  espacio
  if pm trim-caches 999999999999 >/dev/null 2>&1; then
    echo "  Después:"
    espacio
  else
    echo "  [x] esta tele no deja limpiar la caché desde aquí; hazlo app por app en Ajustes > Apps"
  fi
  am kill-all >/dev/null 2>&1

  despues=$(memoria MemAvailable)
  if [ -n "$antes" ] && [ -n "$despues" ]; then
    echo
    echo "Memoria disponible: $(kb_a_mb "$antes") MB antes -> $(kb_a_mb "$despues") MB ahora"
  fi
  echo
  echo "Listo. Reiniciar la tele ahora hace que el cambio se note más."
}

compilar() {
  if [ "$sdk" -lt 24 ]; then
    echo "Esto necesita Android 7 o superior; esta tele tiene API $sdk."
    return
  fi
  echo "Optimizando el código de todas las apps para que abran más rápido."
  echo "Tarda entre 5 y 20 minutos. No apagues la tele ni cierres esta ventana."
  cmd package bg-dexopt-job && echo "[ok] Terminado."
}

restaurar() {
  echo "TV TURBO · DESHACER TODO"
  titulo "Reactivando apps"
  if [ -s "$DESACTIVADAS" ]; then
    cp "$DESACTIVADAS" "$DIR/pendientes.txt"
    while read -r paq; do
      [ -n "$paq" ] && reactivar_uno "$paq"
    done < "$DIR/pendientes.txt"
    rm -f "$DIR/pendientes.txt"
  else
    echo "  no había apps desactivadas por TV Turbo"
  fi
  titulo "Ajustes originales"
  if [ -s "$AJUSTES" ]; then
    while read -r tabla clave valor; do
      [ -n "$clave" ] || continue
      if [ -z "$valor" ] || [ "$valor" = "null" ]; then
        settings delete "$tabla" "$clave" >/dev/null 2>&1
      else
        settings put "$tabla" "$clave" "$valor"
      fi
      echo "  [ok] $clave"
    done < "$AJUSTES"
    : > "$AJUSTES"
  else
    echo "  no había ajustes que restaurar"
  fi
  echo
  echo "La tele quedó como estaba antes de TV Turbo."
}

accion="$1"
[ $# -gt 0 ] && shift

case "$accion" in
  diagnostico) diagnostico ;;
  optimizar)   optimizar ;;
  opcionales)  lista_presentes "$OPCIONALES" ;;
  desactivar)  for paq in "$@"; do desactivar_uno "$paq"; done ;;
  reactivar)   for paq in "$@"; do reactivar_uno "$paq"; done ;;
  compilar)    compilar ;;
  restaurar)   restaurar ;;
  *)
    echo "Uso: sh tvturbo.sh diagnostico|optimizar|opcionales|desactivar PAQ...|reactivar PAQ...|compilar|restaurar"
    exit 1 ;;
esac
