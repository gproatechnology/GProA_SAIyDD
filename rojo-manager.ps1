#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gestor interactivo de Rojo y backend para SAIyDD
.DESCRIPTION
    Inicia/detiene el servidor Rojo y el backend (uvicorn), muestra
    puertos, logs y estado. Ejecuta el flujo completo de integración
    (auth de cuenta de servicio + sesión de prueba + progreso) y
    guarda el estado (apiUrl, token, childId) en un archivo temporal
    para la prueba manual en Studio.
.NOTES
    Ejecutar desde: C:\Users\X1\OneDrive\Documentos\Python_VS Code\GProA\SAIyDD
#>

param(
    [int]$Port = 34872,
    [string]$ProjectFile = "rojo/default.project.json"
)

$SAIYDD_ROOT = "C:\Users\X1\OneDrive\Documentos\Python_VS Code\GProA\SAIyDD"
$ROJO_CMD = "powershell.exe"
$ROJO_ARGS_BASE = "-ExecutionPolicy Bypass -File `"$env:APPDATA\npm\rojo.ps1`""
$BACKEND_PORT = 8000
$BACKEND_DIR = Join-Path $SAIYDD_ROOT "backend"
$VENV_PYTHON = Join-Path $SAIYDD_ROOT ".venv\Scripts\python.exe"
$SECRETS_FILE = Join-Path $SAIYDD_ROOT "rojo\server\secrets.lua"
$STATE_FILE = Join-Path $env:TEMP "saiydd-state.json"
$script:rojoPid = $null
$script:backendPid = $null

# --- Utilidades HTTP (curl.exe: funciona contra localhost en este entorno) ---

function Invoke-HttpJson {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Body = "",
        [string]$Token = ""
    )
    $tmp = [System.IO.Path]::GetTempFileName()
    $curlArgs = @("-s", "-X", $Method, $Url, "-o", $tmp, "-w", "%{http_code}")
    if ($Body) {
        # El body va en archivo: PS 5.1 manglea las comillas del JSON
        # al pasarlo como argumento directo a curl.exe.
        $bodyFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $bodyFile -Value $Body -NoNewline
        $curlArgs += @("-H", "Content-Type: application/json", "--data", "@$bodyFile")
    }
    if ($Token) {
        $curlArgs += @("-H", "Authorization: Bearer $Token")
    }
    $code = & curl.exe @curlArgs 2>$null
    if ($Body) {
        Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue
    }
    $content = Get-Content $tmp -Raw -ErrorAction SilentlyContinue
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    $json = $null
    if ($content) {
        try { $json = $content | ConvertFrom-Json } catch { $json = $null }
    }
    return @{ code = [int]$code; json = $json; raw = $content }
}

# --- Configuración de la cuenta de servicio (rojo/server/secrets.lua) ---

function Get-Secrets {
    if (-not (Test-Path $SECRETS_FILE)) {
        Write-Host "[ERROR] No existe rojo/server/secrets.lua" -ForegroundColor Red
        Write-Host "        Copiá rojo/secrets.example.lua y configurá las credenciales." -ForegroundColor Red
        return $null
    }
    $content = Get-Content $SECRETS_FILE -Raw
    $secrets = @{
        apiUrl = "http://localhost:8000"
        email = ""
        password = ""
    }
    if ($content -match 'apiUrl\s*=\s*"([^"]+)"') { $secrets.apiUrl = $Matches[1] }
    if ($content -match 'email\s*=\s*"([^"]+)"') { $secrets.email = $Matches[1] }
    if ($content -match 'password\s*=\s*"([^"]+)"') { $secrets.password = $Matches[1] }
    if (-not $secrets.email -or -not $secrets.password) {
        Write-Host "[ERROR] secrets.lua incompleto (faltan email/password)" -ForegroundColor Red
        return $null
    }
    return $secrets
}

# --- Backend (uvicorn) ---

function Get-BackendListener {
    return Get-NetTCPConnection -LocalPort $BACKEND_PORT -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Start-Backend {
    $existing = Get-BackendListener
    if ($existing) {
        Write-Host "[i] Backend ya corriendo (PID: $($existing.OwningProcess)) en :$BACKEND_PORT" -ForegroundColor Cyan
        return $true
    }
    if (-not (Test-Path $VENV_PYTHON)) {
        Write-Host "[ERROR] No se encontró el venv en: $VENV_PYTHON" -ForegroundColor Red
        return $false
    }
    Write-Host "`n[*] Iniciando backend uvicorn en :$BACKEND_PORT..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath $VENV_PYTHON -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$BACKEND_PORT", "--log-level", "warning" -WorkingDirectory $BACKEND_DIR -WindowStyle Hidden -PassThru
    if (-not $proc) {
        Write-Host "[ERROR] No se pudo iniciar el backend" -ForegroundColor Red
        return $false
    }
    $script:backendPid = $proc.Id
    $ready = $false
    for ($i = 0; $i -lt 40; $i++) {
        $r = Invoke-HttpJson -Method GET -Url "http://127.0.0.1:$BACKEND_PORT/api/health"
        if ($r.code -eq 200) { $ready = $true; break }
        Start-Sleep -Milliseconds 500
    }
    if ($ready) {
        Write-Host "[OK] Backend listo (PID: $($script:backendPid))" -ForegroundColor Green
        Write-Host "[i] URL: http://127.0.0.1:$BACKEND_PORT/api/health" -ForegroundColor Cyan
        return $true
    }
    Write-Host "[ERROR] El backend no respondió en :$BACKEND_PORT" -ForegroundColor Red
    return $false
}

function Stop-Backend {
    $existing = Get-BackendListener
    if ($existing) {
        try {
            Stop-Process -Id $existing.OwningProcess -Force -ErrorAction Stop
            Write-Host "[OK] Backend detenido (PID: $($existing.OwningProcess))" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] No se pudo detener: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[i] Backend no está corriendo" -ForegroundColor Gray
    }
    $script:backendPid = $null
}

function Toggle-Backend {
    if (Get-BackendListener) {
        Stop-Backend
    } else {
        if (Start-Backend) {
            Write-Host "[i] El backend queda corriendo en segundo plano" -ForegroundColor Cyan
        }
    }
    Read-Enter
}

# --- Auth de la cuenta de servicio ---

function Get-ServiceToken {
    param([hashtable]$Secrets)
    $creds = (@{ email = $Secrets.email; password = $Secrets.password } | ConvertTo-Json -Compress)
    $login = Invoke-HttpJson -Method POST -Url "$($Secrets.apiUrl)/api/auth/login" -Body $creds
    if ($login.code -eq 200) {
        return $login.json.accessToken
    }
    # Primera vez: registrar la cuenta de servicio y reintentar.
    $registerBody = (@{
        email = $Secrets.email
        display_name = "Studio Service"
        password = $Secrets.password
    } | ConvertTo-Json -Compress)
    $reg = Invoke-HttpJson -Method POST -Url "$($Secrets.apiUrl)/api/auth/register" -Body $registerBody
    if ($reg.code -eq 201 -or $reg.code -eq 409) {
        $login = Invoke-HttpJson -Method POST -Url "$($Secrets.apiUrl)/api/auth/login" -Body $creds
        if ($login.code -eq 200) {
            return $login.json.accessToken
        }
    }
    Write-Host "[ERROR] No se pudo autenticar la cuenta de servicio (login HTTP $($login.code))" -ForegroundColor Red
    return $null
}

# --- Flujo completo de integración ---

function Invoke-FullFlow {
    Write-Host "`n[*] Flujo completo SaIyDD (backend + cuenta de servicio + sesión de prueba)" -ForegroundColor Yellow

    if (-not (Start-Backend)) { Read-Enter; return }

    $secrets = Get-Secrets
    if ($null -eq $secrets) { Read-Enter; return }
    Write-Host "[i] API: $($secrets.apiUrl)" -ForegroundColor Cyan

    $token = Get-ServiceToken -Secrets $secrets
    if (-not $token) { Read-Enter; return }
    Write-Host "[OK] Cuenta de servicio autenticada: $($secrets.email)" -ForegroundColor Green

    $childBody = (@{ name = "Nico"; avatar = "robot" } | ConvertTo-Json -Compress)
    $child = Invoke-HttpJson -Method POST -Url "$($secrets.apiUrl)/api/children" -Body $childBody -Token $token
    if ($child.code -ne 201) {
        Write-Host "[ERROR] No se pudo crear el niño de prueba (HTTP $($child.code))" -ForegroundColor Red
        Read-Enter; return
    }
    $childId = $child.json.id
    Write-Host "[OK] Niño de prueba creado: $childId" -ForegroundColor Green

    # Payload idéntico a Shared.buildSessionPayload del cliente Roblox.
    $sessionBody = (@{
        childId = $childId
        activityId = "act_001"
        score = 100
        durationSeconds = 90
        interactions = @(
            @{ promptIndex = 0; selectedIndex = 1; correct = $true; responseTimeMs = 2500 }
        )
    } | ConvertTo-Json -Compress -Depth 5)
    $session = Invoke-HttpJson -Method POST -Url "$($secrets.apiUrl)/api/sessions" -Body $sessionBody -Token $token
    if ($session.code -ne 201) {
        Write-Host "[ERROR] No se pudo registrar la sesión de prueba (HTTP $($session.code))" -ForegroundColor Red
        Read-Enter; return
    }
    Write-Host "[OK] Sesión registrada: $($session.json.id)" -ForegroundColor Green

    $progress = Invoke-HttpJson -Method GET -Url "$($secrets.apiUrl)/api/children/$childId/progress" -Token $token
    if ($progress.code -eq 200) {
        Write-Host ("[OK] Progreso: sesiones={0} promedio={1}% tiempo={2}s" -f $progress.json.totalSessions, $progress.json.averageScore, $progress.json.totalSeconds) -ForegroundColor Green
    } else {
        Write-Host "[WARN] No se pudo leer el progreso (HTTP $($progress.code))" -ForegroundColor Yellow
    }

    $state = @{
        apiUrl = $secrets.apiUrl
        token = $token
        childId = $childId
        savedAt = (Get-Date).ToString("o")
    }
    $state | ConvertTo-Json -Compress | Set-Content -Path $STATE_FILE -NoNewline
    Write-Host "[i] Estado guardado en: $STATE_FILE" -ForegroundColor Cyan
    Write-Host "[i] Usá childId=$childId en el LocalScript de prueba de Studio" -ForegroundColor Cyan
    Read-Enter
}

# --- Estado integral ---

function Show-FullStatus {
    Write-Host "`n[*] Estado integral" -ForegroundColor Yellow

    foreach ($port in @($Port, $BACKEND_PORT)) {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($conn) {
            Write-Host "  [OK] Puerto $port escuchando (PID $($conn.OwningProcess))" -ForegroundColor Green
        } else {
            Write-Host "  [--] Puerto $port libre" -ForegroundColor Gray
        }
    }

    $rojoProcs = Get-Process -Name "rojo" -ErrorAction SilentlyContinue
    if ($rojoProcs) {
        Write-Host "  [OK] rojo.exe: $($rojoProcs.Count) proceso(s)" -ForegroundColor Green
    } else {
        Write-Host "  [--] rojo.exe: no corriendo" -ForegroundColor Gray
    }

    $health = Invoke-HttpJson -Method GET -Url "http://127.0.0.1:$BACKEND_PORT/api/health"
    if ($health.code -eq 200) {
        Write-Host "  [OK] Backend: $($health.json.status) v$($health.json.version)" -ForegroundColor Green
    } else {
        Write-Host "  [--] Backend: no disponible en :$BACKEND_PORT" -ForegroundColor Gray
    }

    $tree = Invoke-HttpJson -Method GET -Url "http://localhost:$Port/show-instances"
    if ($tree.code -eq 200) {
        $needles = @("Shared", "Events", "SAIyDDRecordSession", "SAIyDDHealthCheck", "RemoteEvent", "ServerScriptService", "StarterPlayerScripts")
        $missing = @($needles | Where-Object { $tree.raw -notmatch [Regex]::Escape($_) })
        if ($missing.Count -eq 0) {
            Write-Host "  [OK] Árbol Rojo sincronizado (Shared, Events, Server, Client)" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Árbol Rojo incompleto, falta: $($missing -join ', ')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [--] Rojo serve: no disponible en :$Port" -ForegroundColor Gray
    }

    if (Test-Path $STATE_FILE) {
        $state = Get-Content $STATE_FILE -Raw | ConvertFrom-Json
        Write-Host "  [i] Estado guardado: childId=$($state.childId) (a las $($state.savedAt))" -ForegroundColor Cyan
    } else {
        Write-Host "  [--] Sin estado guardado (ejecutá la opción 8 primero)" -ForegroundColor Gray
    }
    Read-Enter
}

# --- Menú original ---

function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           ROJO MANAGER - SAIyDD                                " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Proyecto: $SAIYDD_ROOT" -ForegroundColor White
    Write-Host "  Puerto Rojo: $Port   |   Backend: :$BACKEND_PORT" -ForegroundColor Yellow
    Write-Host "  Project file: $ProjectFile" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Iniciar servidor Rojo" -ForegroundColor Green
    Write-Host "  [2] Detener servidor Rojo" -ForegroundColor Red
    Write-Host "  [3] Ver logs en vivo (nueva ventana)" -ForegroundColor Cyan
    Write-Host "  [4] Ver estado puertos (netstat)" -ForegroundColor Yellow
    Write-Host "  [5] Cambiar puerto" -ForegroundColor Magenta
    Write-Host "  [6] Probar conexion (curl /show-instances)" -ForegroundColor Blue
    Write-Host "  [7] Iniciar/Detener backend (uvicorn)" -ForegroundColor Green
    Write-Host "  [8] Flujo completo (backend + servicio + sesion)" -ForegroundColor Green
    Write-Host "  [9] Estado integral (puertos, Rojo, backend)" -ForegroundColor Yellow
    Write-Host "  [Q] Salir" -ForegroundColor Gray
    Write-Host ""
}

function Start-RojoServer {
    param($P, $Proj)
    Write-Host "`n[*] Iniciando Rojo en puerto $P..." -ForegroundColor Yellow
    Set-Location $SAIYDD_ROOT

    $proc = Start-Process -FilePath $ROJO_CMD -ArgumentList "$ROJO_ARGS_BASE serve $Proj --port $P" -PassThru
    if ($proc) {
        $script:rojoPid = $proc.Id
        Write-Host "[OK] Servidor iniciado (PID: $($proc.Id))" -ForegroundColor Green
        Write-Host "[i] URL: http://localhost:$P" -ForegroundColor Cyan
        Write-Host "[i] Instancias: http://localhost:$P/show-instances" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Error al iniciar" -ForegroundColor Red
    }
    Read-Enter
}

function Stop-RojoServer {
    Write-Host "`n[*] Deteniendo servidores Rojo..." -ForegroundColor Yellow
    $found = $false
    Get-Process -Name "rojo" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "[i] Matando PID: $($_.Id)" -ForegroundColor Cyan
        Stop-Process -Id $_.Id -Force
        $found = $true
    }
    if ($found) { Write-Host "[OK] Detenidos" -ForegroundColor Green }
    else { Write-Host "[i] No habia procesos rojo.exe" -ForegroundColor Gray }
    $script:rojoPid = $null
    Read-Enter
}

function Show-Logs {
    param($P)
    Write-Host "`n[*] Abriendo logs en nueva ventana..." -ForegroundColor Yellow
    $rojoPath = "$env:APPDATA\npm\rojo.ps1"
    $cmdArgs = "/k", "cd /d `"$SAIYDD_ROOT`" && powershell.exe -ExecutionPolicy Bypass -File `"$rojoPath`" serve $ProjectFile --port $P"

    # Try Windows Terminal first, fallback to cmd
    if (Get-Command "wt.exe" -ErrorAction SilentlyContinue) {
        $argList = "powershell.exe", "-ExecutionPolicy", "Bypass", "-File", "`"$rojoPath`"", "serve", "`"$ProjectFile`"", "--port", "$P"
        Start-Process -FilePath "wt.exe" -ArgumentList $argList -WorkingDirectory $SAIYDD_ROOT -ErrorAction SilentlyContinue
    } else {
        Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs
    }
    Read-Enter
}

function Show-Ports {
    Write-Host "`n[*] Puertos en uso (3487x):" -ForegroundColor Yellow
    netstat -ano | Select-String "3487" | ForEach-Object { Write-Host "  $_" }
    if (-not $?) { Write-Host "  (ninguno)" -ForegroundColor Gray }
    Write-Host ""
    Write-Host "[*] Procesos rojo.exe:" -ForegroundColor Yellow
    $procs = Get-Process -Name "rojo" -ErrorAction SilentlyContinue
    if ($procs) { $procs | Format-Table Id, ProcessName, CPU, WS -AutoSize | Out-Host }
    else { Write-Host "  (ninguno)" -ForegroundColor Gray }
    Read-Enter
}

function Test-Connection {
    param($P)
    Write-Host "`n[*] Probando http://localhost:$P/show-instances..." -ForegroundColor Yellow
    $r = Invoke-HttpJson -Method GET -Url "http://localhost:$P/show-instances"
    if ($r.code -eq 200) {
        Write-Host "[OK] Servidor responde (HTTP 200)" -ForegroundColor Green
        if ($r.raw -match "SAIyDD") { Write-Host "[OK] Proyecto detectado: SAIyDD" -ForegroundColor Green }
    } else {
        Write-Host "[WARN] HTTP $($r.code)" -ForegroundColor Yellow
    }
    Read-Enter
}

function Set-Port {
    param([ref]$P)
    $new = Read-Host "`nNuevo puerto (actual: $($P.Value))"
    if ($new -match "^\d+$" -and [int]$new -ge 1024 -and [int]$new -le 65535) {
        $P.Value = [int]$new
        Write-Host "[OK] Puerto cambiado a $($P.Value)" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Puerto invalido" -ForegroundColor Red
    }
}

function Read-Enter {
    Write-Host ""
    Read-Host "Presiona Enter para continuar" | Out-Null
}

# --- Cleanup on exit ---
function Cleanup {
    if ($script:rojoPid) {
        Stop-Process -Id $script:rojoPid -Force -ErrorAction SilentlyContinue
    }
    if ($script:backendPid) {
        Stop-Process -Id $script:backendPid -Force -ErrorAction SilentlyContinue
    }
}
$global:CleanupScript = $function:Cleanup

# --- Main Loop ---
$portRef = [ref]$Port
$running = $true
try {
    while ($running) {
        Show-Menu
        $choice = Read-Host "Selecciona opcion"
        switch ($choice.Trim().ToUpper()) {
            "1" { Start-RojoServer -P $portRef.Value -Proj $ProjectFile }
            "2" { Stop-RojoServer }
            "3" { Show-Logs -P $portRef.Value }
            "4" { Show-Ports }
            "5" { Set-Port -P $portRef }
            "6" { Test-Connection -P $portRef.Value }
            "7" { Toggle-Backend }
            "8" { Invoke-FullFlow }
            "9" { Show-FullStatus }
            "Q" { Write-Host "`n[!] Saliendo..." -ForegroundColor Gray; $running = $false }
            default { Write-Host "[!] Opcion invalida" -ForegroundColor Red; Start-Sleep 1 }
        }
    }
}
finally {
    & $global:CleanupScript
}
