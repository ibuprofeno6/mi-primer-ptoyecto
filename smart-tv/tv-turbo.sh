#!/usr/bin/env bash
# TV Turbo para Mac y Linux. Conecta con la tele por la red y abre el menú.
# Uso: bash tv-turbo.sh

set -u
cd "$(dirname "$0")" || exit 1

SCRIPT_TV=/data/local/tmp/tvturbo.sh
ARCHIVO_IP=.tv-ip
ADB=""
TELE=""

pausa() { echo; read -r -p "Pulsa Enter para continuar..." _; }

buscar_adb() {
  if [ -x platform-tools/adb ]; then ADB=./platform-tools/adb
  elif command -v adb >/dev/null 2>&1; then ADB=adb
  fi
  [ -n "$ADB" ] && return 0

  echo "Hace falta 'adb', la herramienta oficial de Google para hablar con equipos Android."
  read -r -p "¿La descargo ahora en esta carpeta (unos 15 MB)? [S/n] " r
  case "$r" in [nN]*) exit 1 ;; esac
  case "$(uname -s)" in
    Darwin) so=darwin ;;
    *)      so=linux ;;
  esac
  curl -fL# -o platform-tools.zip \
    "https://dl.google.com/android/repository/platform-tools-latest-$so.zip" \
    && unzip -qo platform-tools.zip && rm -f platform-tools.zip
  if [ ! -x platform-tools/adb ]; then
    echo "No se pudo descargar. Revisa tu conexión o instala adb a mano (ver README)."
    exit 1
  fi
  ADB=./platform-tools/adb
}

conectar() {
  local ultima="" destino estado
  [ -f "$ARCHIVO_IP" ] && ultima=$(cat "$ARCHIVO_IP")
  echo "Escribe la IP de la tele (Ajustes > Red > Estado de la red), por ejemplo 192.168.1.50"
  echo "Si tu tele usa 'Depuración inalámbrica', escribe IP:PUERTO tal como aparece ahí."
  read -r -p "IP de la tele${ultima:+ [$ultima]}: " destino
  destino=${destino:-$ultima}
  [ -n "$destino" ] || { echo "Sin IP no puedo seguir."; exit 1; }
  case "$destino" in *:*) ;; *) destino="$destino:5555" ;; esac

  "$ADB" connect "$destino" | tr -d '\r'
  echo
  echo "Mira la tele: si aparece '¿Permitir depuración?', marca 'Permitir siempre' y acepta."
  for _ in $(seq 1 45); do
    estado=$("$ADB" -s "$destino" get-state 2>/dev/null | tr -d '\r')
    [ "$estado" = "device" ] && break
    sleep 2
    "$ADB" connect "$destino" >/dev/null 2>&1
  done
  if [ "${estado:-}" != "device" ]; then
    echo
    echo "No logré conectar. Revisa que:"
    echo "  - la tele y esta computadora estén en la misma red"
    echo "  - 'Depuración por USB' (o 'Depuración de red') esté activada en Opciones de desarrollador"
    echo "  - aceptaste el aviso en la tele"
    echo "En Google TV con Android 11 o más nuevo usa la opción 'Emparejar' del menú."
    return 1
  fi
  echo "$destino" | cut -d: -f1 > "$ARCHIVO_IP"
  TELE=$destino
  local tmp
  tmp=$(mktemp)
  tr -d '\r' < tv/tvturbo.sh > "$tmp"
  "$ADB" -s "$TELE" push "$tmp" "$SCRIPT_TV" >/dev/null && rm -f "$tmp"
  echo "Conectado a $("$ADB" -s "$TELE" shell getprop ro.product.model | tr -d '\r')."
}

emparejar() {
  echo "En la tele: Opciones de desarrollador > Depuración inalámbrica > Vincular con código."
  read -r -p "IP:PUERTO que muestra la ventana de vinculación: " par
  read -r -p "Código de 6 dígitos: " codigo
  "$ADB" pair "$par" "$codigo"
  echo "Ahora conecta usando la IP:PUERTO de la pantalla principal de Depuración inalámbrica."
  conectar
}

tv() { "$ADB" -s "$TELE" shell sh "$SCRIPT_TV" "$@" | tr -d '\r'; }

respaldar() {
  mkdir -p respaldo
  "$ADB" -s "$TELE" pull /data/local/tmp/tvturbo/desactivadas.txt respaldo/ >/dev/null 2>&1
  "$ADB" -s "$TELE" pull /data/local/tmp/tvturbo/ajustes-originales.txt respaldo/ >/dev/null 2>&1
}

diagnostico() {
  local archivo
  archivo="diagnostico-$(date +%Y%m%d-%H%M).txt"
  tv diagnostico | tee "$archivo"
  echo
  echo "Guardado en $(pwd)/$archivo"
  echo "Si quieres más ajustes a la medida, pega ese archivo en tu conversación con Claude."
}

quitar_opcionales() {
  local lineas=() i=1 elegidas=() n
  while IFS= read -r l; do [ -n "$l" ] && lineas+=("$l"); done < <(tv opcionales)
  if [ ${#lineas[@]} -eq 0 ]; then
    echo "No hay apps opcionales activas en esta tele."
  else
    echo "Apps que puedes quitar si no las usas:"
    for l in "${lineas[@]}"; do printf '  %d) %s\n' "$i" "${l#*|}"; i=$((i + 1)); done
  fi
  echo
  echo "Escribe los números separados por espacios (ej. 1 3)."
  echo "También puedes escribir el nombre exacto de un paquete que te haya sugerido Claude."
  read -r -p "> " -a respuesta
  for n in "${respuesta[@]:-}"; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#lineas[@]} ]; then
      elegidas+=("${lineas[$((n - 1))]%%|*}")
    elif [[ "$n" =~ ^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$ ]]; then
      elegidas+=("$n")
    fi
  done
  [ ${#elegidas[@]} -gt 0 ] || { echo "No elegiste nada."; return; }
  tv desactivar "${elegidas[@]}"
  respaldar
}

menu() {
  while true; do
    clear
    cat <<EOF
==============================
  TV TURBO · $TELE
==============================
 1) Diagnóstico (no cambia nada)
 2) Optimización segura
 3) Quitar apps que no uso
 4) Optimizar el arranque de apps (tarda 5-20 min)
 5) Reiniciar la tele
 6) Deshacer todo
 7) Conectar a otra tele
 0) Salir
EOF
    read -r -p "Elige: " op
    case "$op" in
      1) diagnostico; pausa ;;
      2) tv optimizar; respaldar; pausa ;;
      3) quitar_opcionales; pausa ;;
      4) tv compilar; pausa ;;
      5) "$ADB" -s "$TELE" reboot; echo "Reiniciando. Vuelve a conectar cuando encienda."; pausa; conectar || pausa ;;
      6) tv restaurar; respaldar; pausa ;;
      7) conectar || pausa ;;
      0) "$ADB" disconnect "$TELE" >/dev/null 2>&1; exit 0 ;;
    esac
  done
}

buscar_adb
echo "TV Turbo · usando $ADB"
echo
echo " 1) Conectar (Android TV con 'Depuración por USB' activada)"
echo " 2) Emparejar con código (Google TV / Android 11+ con 'Depuración inalámbrica')"
read -r -p "Elige [1]: " modo
if [ "${modo:-1}" = "2" ]; then emparejar || exit 1; else conectar || exit 1; fi
menu
