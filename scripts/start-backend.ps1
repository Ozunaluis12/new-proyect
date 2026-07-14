param(
    [string]$EnvFile = '.env.local.ps1',
    [string]$BackendProject = '..\LoginovaBackend\LoginovaAPI',
    [string]$BackendUrl = 'http://0.0.0.0:5105',
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Resolve-Path -Path (Join-Path $scriptRoot $BackendProject)
$healthUrl = 'http://127.0.0.1:5105/health'

function Load-LocalEnv {
    param([string]$Path)

    $resolvedPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path $scriptRoot $Path
    }

    if (-not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path $resolvedPath)) {
        Write-Host "Cargando configuración local desde: $resolvedPath" -ForegroundColor Cyan
        . $resolvedPath
    } else {
        Write-Host "No se encontró el archivo de entorno: $resolvedPath" -ForegroundColor Yellow
    }
}

function Is-BackendRunning {
    try {
        Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Wait-BackendReady {
    param([int]$TimeoutSeconds = 30)
    $start = Get-Date
    while ((Get-Date) -lt $start.AddSeconds($TimeoutSeconds)) {
        if (Is-BackendRunning) {
            Write-Host 'Backend listo.' -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 1
    }
    Write-Host 'El backend no respondió a tiempo.' -ForegroundColor Red
    exit 1
}

Write-Host 'Start-backend: preparando el backend para ejecución local.' -ForegroundColor Cyan
Load-LocalEnv -Path $EnvFile

if ($Restore) {
    Write-Host 'Restaurando y compilando backend...' -ForegroundColor Yellow
    Push-Location $backendPath
    dotnet restore
    dotnet build -c Release --no-restore
    Pop-Location
}

if (Is-BackendRunning) {
    Write-Host 'El backend ya está en ejecución.' -ForegroundColor Green
} else {
    Write-Host "Iniciando backend en: $BackendUrl" -ForegroundColor Cyan
    Start-Process -FilePath 'dotnet' -ArgumentList @('run', '--urls', $BackendUrl) -WorkingDirectory $backendPath | Out-Null
    Wait-BackendReady -TimeoutSeconds 30
}
