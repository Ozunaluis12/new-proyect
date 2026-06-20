# Script de configuración del entorno de desarrollo
# Uso: .\setup-dev.ps1

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Configuración del Entorno - Loginova (Flutter + .NET)   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 1. Verificar Flutter
Write-Host "`n[1/4] Verificando Flutter..." -ForegroundColor Yellow
if (flutter --version) {
    Write-Host "✅ Flutter detectado" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter no detectado. Instálalo desde https://flutter.dev/docs/get-started/install" -ForegroundColor Red
}

# 2. Verificar .NET
Write-Host "`n[2/4] Verificando .NET SDK..." -ForegroundColor Yellow
if (dotnet --version) {
    Write-Host "✅ .NET SDK detectado" -ForegroundColor Green
} else {
    Write-Host "❌ .NET SDK no detectado. Instálalo desde https://dotnet.microsoft.com/download" -ForegroundColor Red
}

# 3. Configurar Frontend
Write-Host "`n[3/4] Configurando Frontend (Flutter)..." -ForegroundColor Yellow
cd Loginova
if (flutter pub get) {
    Write-Host "✅ Dependencias de Flutter instaladas" -ForegroundColor Green
} else {
    Write-Host "❌ Error al instalar dependencias de Flutter" -ForegroundColor Red
}
cd ..

# 4. Configurar Backend
Write-Host "`n[4/4] Configurando Backend (.NET)..." -ForegroundColor Yellow
cd LoginovaBackend/LoginovaAPI
if (dotnet restore) {
    Write-Host "✅ Dependencias de .NET restauradas" -ForegroundColor Green
} else {
    Write-Host "❌ Error al restaurar dependencias de .NET" -ForegroundColor Red
}
cd ../..

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Configuración completada                              ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nPróximos pasos:" -ForegroundColor Cyan
Write-Host "1. Abre el archivo 'loginova.code-workspace' en VS Code" -ForegroundColor White
Write-Host "2. Ejecuta '.\scripts\run-all.ps1' para iniciar frontend + backend" -ForegroundColor White
Write-Host "3. O usa los comandos individuales en el README.md" -ForegroundColor White
