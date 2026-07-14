param(
    [string]$EnvFile = '.env.local.ps1',
    [string]$ApiBaseUrl = 'http://127.0.0.1:5105/api',
    [string]$Device = 'windows',
    [switch]$PubGet
)

function Get-LocalIPv4Address {
    $interfaces = Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp -ErrorAction SilentlyContinue
    if (-not $interfaces) {
        $interfaces = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue
    }

    foreach ($iface in $interfaces) {
        if ($iface.IPAddress -and $iface.IPAddress -ne '127.0.0.1' -and $iface.IPAddress -notlike '169.254.*') {
            return $iface.IPAddress
        }
    }

    return $null
}

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$startBackendScript = Join-Path $scriptRoot 'start-backend.ps1'
$flutterPath = Resolve-Path -Path (Join-Path $scriptRoot '..\Loginova')

if (-not (Test-Path $startBackendScript)) {
    Write-Host "No se encontró $startBackendScript. Ejecuta start-backend.ps1 o revisa la carpeta scripts." -ForegroundColor Red
    exit 1
}

if ($ApiBaseUrl -eq 'http://127.0.0.1:5105/api') {
    $localIp = Get-LocalIPv4Address
    if ($localIp) {
        Write-Host "Run-local: detectada IP local $localIp. Usando backend accesible desde el dispositivo." -ForegroundColor Yellow
        $ApiBaseUrl = "http://$($localIp):5105/api"
    } else {
        Write-Host 'Run-local: no se pudo detectar una IP local. Si usas un dispositivo físico, pasa -ApiBaseUrl con la IP de tu PC.' -ForegroundColor Yellow
    }
}

$resolvedEnvFile = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path $scriptRoot $EnvFile
}

Write-Host 'Run-local: asegurando backend y lanzando Flutter en PC.' -ForegroundColor Cyan
& $startBackendScript -EnvFile $resolvedEnvFile

Push-Location $flutterPath
if ($PubGet) {
    Write-Host 'Actualizando dependencias Flutter...' -ForegroundColor Yellow
    flutter pub get
}

Write-Host 'Ejecutando Flutter run...' -ForegroundColor Cyan
flutter run -d $Device --dart-define=API_BASE_URL=$ApiBaseUrl
$exitCode = $LASTEXITCODE
Pop-Location
exit $exitCode
