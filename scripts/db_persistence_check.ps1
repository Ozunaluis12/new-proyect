$base = 'http://127.0.0.1:5105/api'
$body = @{ correo = 'admin@loginova.com'; password = 'admin123' } | ConvertTo-Json
try {
    $login = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -ContentType 'application/json' -Body $body
    Write-Host "TOKEN_OK: $($login.token)"
} catch {
    Write-Host "LOGIN_FAIL: $($_.Exception.Message)"
    exit 1
}
$headers = @{ Authorization = "Bearer $($login.token)" }
$newClient = @{ nombre = "Smoke DB Cliente $(Get-Date -Format yyyyMMddHHmmss)"; telefono = '3000000000'; direccion = 'Auto test'; ciudad = 'TestLand' } | ConvertTo-Json
try {
    $create = Invoke-RestMethod -Uri "$base/clientes" -Method Post -Headers $headers -ContentType 'application/json' -Body $newClient
    Write-Host "CLIENT_CREATED_ID: $($create.id)"
    Write-Host "CLIENT_CREATED_NAME: $($create.nombre)"
} catch {
    Write-Host "CREATE_FAIL: $($_.Exception.Message)"
    exit 1
}
try {
    $list = Invoke-RestMethod -Uri "$base/clientes" -Method Get -Headers $headers
    $found = $list | Where-Object { $_.id -eq $create.id }
    if ($null -ne $found) {
        Write-Host "CLIENT_FOUND: $($found.nombre)"
        exit 0
    } else {
        Write-Host 'CLIENT_NOT_FOUND'
        exit 1
    }
} catch {
    Write-Host "LIST_FAIL: $($_.Exception.Message)"
    exit 1
}
