#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gestor interactivo de Rojo para SAIyDD
.DESCRIPTION
    Inicia/detiene servidor Rojo, muestra puertos, logs y estado
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
$script:rojoPid = $null

function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           ROJO MANAGER - SAIyDD                                " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Proyecto: $SAIYDD_ROOT" -ForegroundColor White
    Write-Host "  Puerto actual: $Port" -ForegroundColor Yellow
    Write-Host "  Project file: $ProjectFile" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Iniciar servidor Rojo" -ForegroundColor Green
    Write-Host "  [2] Detener servidor Rojo" -ForegroundColor Red
    Write-Host "  [3] Ver logs en vivo (nueva ventana)" -ForegroundColor Cyan
    Write-Host "  [4] Ver estado puertos (netstat)" -ForegroundColor Yellow
    Write-Host "  [5] Cambiar puerto" -ForegroundColor Magenta
    Write-Host "  [6] Probar conexion (curl /show-instances)" -ForegroundColor Blue
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
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:$P/show-instances" -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -eq 200) {
            Write-Host "[OK] Servidor responde (HTTP 200)" -ForegroundColor Green
            if ($resp.Content -match "SAIyDD") { Write-Host "[OK] Proyecto detectado: SAIyDD" -ForegroundColor Green }
        } else {
            Write-Host "[WARN] HTTP $($resp.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Sin respuesta: $($_.Exception.Message)" -ForegroundColor Red
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
            "Q" { Write-Host "`n[!] Saliendo..." -ForegroundColor Gray; $running = $false }
            default { Write-Host "[!] Opcion invalida" -ForegroundColor Red; Start-Sleep 1 }
        }
    }
}
finally {
    & $global:CleanupScript
}