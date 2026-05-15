# MS USB Display - Optimizador 1080p
# Ejecutar como Administrador despues de instalar MSDisplay_Windows_V2.0.1.7.3.exe

$ErrorActionPreference = 'Stop'
$installDir = 'C:\Program Files\USM USB Display'
$app = Join-Path $installDir 'WinUsbDisplay.exe'
$configTarget = Join-Path $installDir 'config.ini'
$configSource = Join-Path $PSScriptRoot 'config_1080p_optimizado.ini'

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Ejecuta este script como Administrador.'
    }
}

Assert-Admin

if (-not (Test-Path $app)) {
    Write-Host 'No se encontro WinUsbDisplay.exe. Instalando primero el paquete oficial...'
    $installer = Join-Path $PSScriptRoot 'MSDisplay_Windows_V2.0.1.7.3.exe'
    if (-not (Test-Path $installer)) { throw 'No se encontro el instalador oficial en esta carpeta.' }
    Start-Process -FilePath $installer -Wait
}

if (-not (Test-Path $app)) {
    throw 'La instalacion no dejo WinUsbDisplay.exe en C:\Program Files\USM USB Display.'
}

$backupDir = Join-Path $PSScriptRoot ('backup_' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
if (Test-Path $configTarget) { Copy-Item $configTarget (Join-Path $backupDir 'config.ini.original') -Force }
pnputil /enum-devices /connected > (Join-Path $backupDir 'pnp_connected.txt') 2>&1
pnputil /enum-drivers > (Join-Path $backupDir 'drivers.txt') 2>&1

Get-Process WinUsbDisplay -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

Copy-Item $configSource $configTarget -Force

New-Item -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $app -Value 'GpuPreference=2;' -PropertyType String -Force | Out-Null

# Desactiva suspension selectiva USB en el plan actual para evitar micro-cortes/ahorro agresivo.
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
powercfg /S SCHEME_CURRENT | Out-Null

Start-Process -FilePath $app -WorkingDirectory $installDir
Start-Sleep -Seconds 3
$proc = Get-Process WinUsbDisplay -ErrorAction SilentlyContinue
if ($proc) { $proc.PriorityClass = 'High' }

Write-Host ''
Write-Host 'Listo: perfil 1080p optimizado aplicado.' -ForegroundColor Green
Write-Host 'Backup creado en:' $backupDir
Write-Host 'Nota: la rotacion vertical nativa sigue limitada por el driver cerrado.' -ForegroundColor Yellow
Read-Host 'Presiona Enter para salir'
