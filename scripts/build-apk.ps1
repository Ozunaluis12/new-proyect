param(
    [string]$ApiBaseUrl = 'http://127.0.0.1:5105/api',
    [string]$FlutterProject = '..\Loginova',
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

if ($ApiBaseUrl -eq 'http://127.0.0.1:5105/api') {
    $localIp = Get-LocalIPv4Address
    if ($localIp) {
        Write-Host "Build-apk: detectada IP local $localIp. Usando backend accesible para dispositivo físico." -ForegroundColor Yellow
        $ApiBaseUrl = "http://$($localIp):5105/api"
    } else {
        Write-Host 'Build-apk: no se pudo detectar una IP local. Si usas un dispositivo físico, pasa -ApiBaseUrl con la IP de tu PC.' -ForegroundColor Yellow
    }
}

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterPath = Resolve-Path -Path (Join-Path $scriptRoot $FlutterProject)

Write-Host 'Build-apk: generando APK con API_BASE_URL=' -NoNewline
Write-Host $ApiBaseUrl -ForegroundColor Cyan

Push-Location $flutterPath
if ($PubGet) {
    Write-Host 'Actualizando dependencias Flutter...' -ForegroundColor Yellow
    flutter pub get
}

flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"
$exitCode = $LASTEXITCODE
Pop-Location
exit $exitCode
