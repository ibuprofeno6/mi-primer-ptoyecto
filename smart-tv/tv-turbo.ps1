# TV Turbo para Windows. Se abre con doble clic en TV-Turbo.bat
# Conecta con la tele por la red y abre el menú.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location -LiteralPath $PSScriptRoot

$ScriptTv = '/data/local/tmp/tvturbo.sh'
$ArchivoIp = Join-Path $PSScriptRoot '.tv-ip'
$script:Adb = $null
$script:Tele = $null

function Pausa { Write-Host ''; [void](Read-Host 'Pulsa Enter para continuar') }

function Buscar-Adb {
  $local = Join-Path $PSScriptRoot 'platform-tools\adb.exe'
  if (Test-Path $local) { $script:Adb = $local; return }
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) { $script:Adb = $cmd.Path; return }

  Write-Host "Hace falta 'adb', la herramienta oficial de Google para hablar con equipos Android."
  $r = Read-Host '¿La descargo ahora en esta carpeta (unos 15 MB)? [S/n]'
  if ($r -match '^[nN]') { exit 1 }
  $zip = Join-Path $PSScriptRoot 'platform-tools.zip'
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Write-Host 'Descargando...'
    Invoke-WebRequest -UseBasicParsing -OutFile $zip `
      -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
    Expand-Archive -Path $zip -DestinationPath $PSScriptRoot -Force
    Remove-Item $zip
  } catch {
    Write-Host "No se pudo descargar: $($_.Exception.Message)"
  }
  if (-not (Test-Path $local)) {
    Write-Host 'Revisa tu conexión o instala adb a mano (ver README).'
    Pausa; exit 1
  }
  $script:Adb = $local
}

function Conectar {
  $script:Tele = $null
  $ultima = ''
  if (Test-Path $ArchivoIp) { $ultima = "$(Get-Content $ArchivoIp -TotalCount 1)".Trim() }
  Write-Host 'Escribe la IP de la tele (Ajustes > Red > Estado de la red), por ejemplo 192.168.1.50'
  Write-Host "Si tu tele usa 'Depuración inalámbrica', escribe IP:PUERTO tal como aparece ahí."
  $pregunta = 'IP de la tele'
  if ($ultima) { $pregunta += " [$ultima]" }
  $destino = (Read-Host $pregunta).Trim()
  if (-not $destino) { $destino = $ultima }
  if (-not $destino) { Write-Host 'Sin IP no puedo seguir.'; return }
  if ($destino -notmatch ':') { $destino = "${destino}:5555" }

  & $script:Adb connect $destino | Write-Host
  Write-Host ''
  Write-Host "Mira la tele: si aparece '¿Permitir depuración?', marca 'Permitir siempre' y acepta."
  $estado = ''
  for ($i = 0; $i -lt 45; $i++) {
    $estado = (& $script:Adb -s $destino get-state 2>$null | Out-String).Trim()
    if ($estado -eq 'device') { break }
    Start-Sleep -Seconds 2
    & $script:Adb connect $destino *> $null
  }
  if ($estado -ne 'device') {
    Write-Host ''
    Write-Host 'No logré conectar. Revisa que:'
    Write-Host '  - la tele y esta computadora estén en la misma red'
    Write-Host "  - 'Depuración por USB' (o 'Depuración de red') esté activada en Opciones de desarrollador"
    Write-Host '  - aceptaste el aviso en la tele'
    Write-Host "En Google TV con Android 11 o más nuevo usa la opción 'Emparejar con código'."
    return
  }
  Set-Content -Path $ArchivoIp -Value ($destino -split ':')[0]

  # Se sube el script con saltos de línea de Linux, aunque Windows los haya cambiado.
  $texto = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'tv\tvturbo.sh')) -replace "`r", ''
  $tmp = Join-Path $env:TEMP 'tvturbo.sh'
  [IO.File]::WriteAllText($tmp, $texto, (New-Object System.Text.UTF8Encoding $false))
  & $script:Adb -s $destino push $tmp $ScriptTv *> $null
  Remove-Item $tmp -ErrorAction SilentlyContinue

  $script:Tele = $destino
  $modelo = (& $script:Adb -s $destino shell getprop ro.product.model | Out-String).Trim()
  Write-Host "Conectado a $modelo."
}

function Emparejar {
  Write-Host 'En la tele: Opciones de desarrollador > Depuración inalámbrica > Vincular con código.'
  $par = (Read-Host 'IP:PUERTO que muestra la ventana de vinculación').Trim()
  $codigo = (Read-Host 'Código de 6 dígitos').Trim()
  & $script:Adb pair $par $codigo | Write-Host
  Write-Host 'Ahora conecta usando la IP:PUERTO de la pantalla principal de Depuración inalámbrica.'
  Conectar
}

function Tv { & $script:Adb -s $script:Tele shell sh $ScriptTv @args }

function Respaldar {
  $dir = Join-Path $PSScriptRoot 'respaldo'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  foreach ($f in 'desactivadas.txt', 'ajustes-originales.txt') {
    & $script:Adb -s $script:Tele pull "/data/local/tmp/tvturbo/$f" (Join-Path $dir $f) *> $null
  }
}

function Diagnostico {
  $archivo = Join-Path $PSScriptRoot ('diagnostico-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmm'))
  $salida = @(Tv diagnostico)
  $salida | ForEach-Object { Write-Host $_ }
  [IO.File]::WriteAllLines($archivo, [string[]]$salida, (New-Object System.Text.UTF8Encoding $false))
  Write-Host ''
  Write-Host "Guardado en $archivo"
  Write-Host 'Si quieres más ajustes a la medida, pega ese archivo en tu conversación con Claude.'
}

function Quitar-Opcionales {
  $lineas = @(Tv opcionales | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
  if ($lineas.Count -eq 0) {
    Write-Host 'No hay apps opcionales activas en esta tele.'
  } else {
    Write-Host 'Apps que puedes quitar si no las usas:'
    for ($i = 0; $i -lt $lineas.Count; $i++) {
      Write-Host ('  {0}) {1}' -f ($i + 1), ($lineas[$i] -split '\|', 2)[1])
    }
  }
  Write-Host ''
  Write-Host 'Escribe los números separados por espacios (ej. 1 3).'
  Write-Host 'También puedes escribir el nombre exacto de un paquete que te haya sugerido Claude.'
  $respuesta = Read-Host '>'
  $elegidas = @()
  foreach ($n in ($respuesta -split '[\s,]+' | Where-Object { $_ })) {
    $num = 0
    if ([int]::TryParse($n, [ref]$num) -and $num -ge 1 -and $num -le $lineas.Count) {
      $elegidas += ($lineas[$num - 1] -split '\|', 2)[0]
    } elseif ($n -match '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$') {
      $elegidas += $n
    }
  }
  if ($elegidas.Count -eq 0) { Write-Host 'No elegiste nada.'; return }
  Tv desactivar @elegidas
  Respaldar
}

function Menu {
  while ($true) {
    Clear-Host
    Write-Host '=============================='
    Write-Host "  TV TURBO · $script:Tele"
    Write-Host '=============================='
    Write-Host ' 1) Diagnóstico (no cambia nada)'
    Write-Host ' 2) Optimización segura'
    Write-Host ' 3) Quitar apps que no uso'
    Write-Host ' 4) Optimizar el arranque de apps (tarda 5-20 min)'
    Write-Host ' 5) Reiniciar la tele'
    Write-Host ' 6) Deshacer todo'
    Write-Host ' 7) Conectar a otra tele'
    Write-Host ' 0) Salir'
    switch (Read-Host 'Elige') {
      '1' { Diagnostico; Pausa }
      '2' { Tv optimizar; Respaldar; Pausa }
      '3' { Quitar-Opcionales; Pausa }
      '4' { Tv compilar; Pausa }
      '5' {
        & $script:Adb -s $script:Tele reboot *> $null
        Write-Host 'Reiniciando. Vuelve a conectar cuando encienda.'
        Pausa; Conectar; if (-not $script:Tele) { Pausa; return }
      }
      '6' { Tv restaurar; Respaldar; Pausa }
      '7' { Conectar; if (-not $script:Tele) { Pausa; return } }
      '0' { & $script:Adb disconnect $script:Tele *> $null; return }
    }
  }
}

Buscar-Adb
Write-Host "TV Turbo · usando $script:Adb"
Write-Host ''
Write-Host " 1) Conectar (Android TV con 'Depuración por USB' activada)"
Write-Host " 2) Emparejar con código (Google TV / Android 11+ con 'Depuración inalámbrica')"
if ((Read-Host 'Elige [1]') -eq '2') { Emparejar } else { Conectar }
if (-not $script:Tele) { Pausa; exit 1 }
Menu
