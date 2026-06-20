# Script para ejecutar Frontend y Backend simultáneamente
# Uso: .\run-all.ps1

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Iniciando Loginova (Frontend + Backend)  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "Loginova") -or -not (Test-Path "LoginovaBackend")) {
    Write-Host "❌ Error: Ejecuta este script desde la carpeta 'new proyect'" -ForegroundColor Red
    exit 1
}

# Limpiar pantalla
Clear-Host

# 1. Iniciar Backend en una nueva ventana
Write-Host "`n📱 Backend: Iniciando servicio .NET..." -ForegroundColor Green
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd LoginovaBackend/LoginovaAPI; dotnet run"

Start-Sleep -Seconds 3

# 2. Iniciar Frontend en otra ventana
Write-Host "🔌 Frontend: Iniciando Flutter..." -ForegroundColor Green
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd Loginova; flutter run"

Write-Host "`n✅ Ambos servicios iniciados en ventanas separadas" -ForegroundColor Green
Write-Host "`n   Backend:  http://localhost:5000" -ForegroundColor Yellow
Write-Host "   Frontend: App Flutter en emulador/dispositivo" -ForegroundColor Yellow
Write-Host "`n⏸️  Presiona Ctrl+C en cualquier ventana para detener el servicio" -ForegroundColor Yellow
