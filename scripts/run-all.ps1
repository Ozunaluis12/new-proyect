# Script para ejecutar Frontend y Backend simultáneamente
# Uso: .\scripts\run-all.ps1

$rootPath = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $rootPath "Loginova"
$backendPath = Join-Path $rootPath "LoginovaBackend\LoginovaAPI"

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Iniciando Loginova (Frontend + Backend)  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan

if (-not (Test-Path $frontendPath) -or -not (Test-Path $backendPath)) {
    Write-Host "❌ Error: Ejecuta este script desde la raíz del workspace 'new proyect'" -ForegroundColor Red
    exit 1
}

Set-Location $rootPath

Write-Host "`n[1/3] Restaurando dependencias del backend..." -ForegroundColor Yellow
Push-Location $backendPath
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "❌ Error al restaurar dependencias del backend" -ForegroundColor Red
    exit 1
}
Pop-Location

Write-Host "`n[2/3] Restaurando dependencias del frontend..." -ForegroundColor Yellow
Push-Location $frontendPath
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "❌ Error al restaurar dependencias del frontend" -ForegroundColor Red
    exit 1
}
Pop-Location

Write-Host "`n[3/3] Iniciando servicios en ventanas separadas..." -ForegroundColor Yellow

Start-Process -FilePath "powershell" -WorkingDirectory $backendPath -ArgumentList "-NoExit", "-Command", "dotnet run"
Start-Process -FilePath "powershell" -WorkingDirectory $frontendPath -ArgumentList "-NoExit", "-Command", "flutter run"

Write-Host "`n✅ Ambos servicios iniciados" -ForegroundColor Green
Write-Host "   Backend:  http://localhost:5105" -ForegroundColor Yellow
Write-Host "   Frontend: Flutter en emulador/dispositivo" -ForegroundColor Yellow
Write-Host "`nPara detenerlos, cierra las dos ventanas de PowerShell o usa Ctrl+C en cada una." -ForegroundColor Yellow
