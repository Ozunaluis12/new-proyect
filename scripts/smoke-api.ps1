param(
    [string]$BaseUrl = "http://localhost:5105/api",
    [string]$Correo = "admin@loginova.com",
    [string]$Password = "admin123"
)

$ErrorActionPreference = "Stop"

function To-Array {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Array]) {
        return $Value
    }

    return @($Value)
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "[FAIL] $Message"
    }

    Write-Host "[OK] $Message" -ForegroundColor Green
}

Write-Host "== Smoke API Loginova ==" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl"

$invalidLoginOk = $false
try {
    $invalidBody = @{ correo = $Correo; password = "password-invalido" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $invalidBody | Out-Null
} catch {
    $response = $_.Exception.Response
    if ($null -ne $response -and $response.StatusCode.value__ -eq 401) {
        $invalidLoginOk = $true
    }
}
Assert-True $invalidLoginOk "Login invalido es rechazado con 401"

$loginBody = @{ correo = $Correo; password = $Password } | ConvertTo-Json
$loginResp = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody

Assert-True (-not [string]::IsNullOrWhiteSpace($loginResp.token)) "Login devuelve token"

$headers = @{ Authorization = "Bearer $($loginResp.token)" }

$usuarios = To-Array ((Invoke-WebRequest -Uri "$BaseUrl/usuarios" -Method Get -Headers $headers -UseBasicParsing).Content | ConvertFrom-Json)
Assert-True ($usuarios.Count -gt 0) "Listado de usuarios disponible"

$usuarioId = $usuarios[0].id
Assert-True ($usuarioId -gt 0) "Usuario valido para prueba"

$testClienteBody = @{
    nombre = "Cliente Smoke $(Get-Date -Format yyyyMMddHHmmss)"
    telefono = "3009990000"
    direccion = "Direccion smoke"
    ciudad = "Bogota"
} | ConvertTo-Json

$clienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes" -Method Post -Headers $headers -ContentType "application/json" -Body $testClienteBody -UseBasicParsing
Assert-True ($clienteResp.StatusCode -eq 201) "Creacion de cliente responde 201"

$clienteCreado = $clienteResp.Content | ConvertFrom-Json
Assert-True ($clienteCreado.id -gt 0) "Cliente creado con ID valido"

$clienteId = $clienteCreado.id

$clienteUpdateBody = @{
    nombre = "$($clienteCreado.nombre) Actualizado"
    telefono = "3009991111"
    direccion = "Direccion smoke actualizada"
    ciudad = "Medellin"
} | ConvertTo-Json

$clienteUpdateResp = Invoke-WebRequest -Uri "$BaseUrl/clientes/$clienteId" -Method Put -Headers $headers -ContentType "application/json" -Body $clienteUpdateBody -UseBasicParsing
Assert-True ($clienteUpdateResp.StatusCode -eq 204) "Actualizacion de cliente responde 204"

$recBody = @{
    clienteId = $clienteId
    usuarioId = $usuarioId
    estado = "Pendiente"
    cantidadPaquetes = 2
    observaciones = "Smoke test $(Get-Date -Format s)"
} | ConvertTo-Json

try {
    $recResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Post -Headers $headers -ContentType "application/json" -Body $recBody -UseBasicParsing
} catch {
    $res = $_.Exception.Response
    if ($null -ne $res) {
        $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
        $body = $reader.ReadToEnd()
        throw "[FAIL] Error creando recogida. Status=$($res.StatusCode.value__) Body=$body"
    }

    throw
}
Assert-True ($recResp.StatusCode -eq 201) "Creacion de recogida responde 201"

$recCreada = $recResp.Content | ConvertFrom-Json
Assert-True ($recCreada.id -gt 0) "Recogida creada con ID valido"

$recUpdateBody = @{
    clienteId = $recCreada.clienteId
    usuarioId = $recCreada.usuarioId
    estado = "En Ruta"
    cantidadPaquetes = 5
    observaciones = "Smoke test actualizado"
} | ConvertTo-Json

$recUpdateResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas/$($recCreada.id)" -Method Put -Headers $headers -ContentType "application/json" -Body $recUpdateBody -UseBasicParsing
Assert-True ($recUpdateResp.StatusCode -eq 204) "Actualizacion de recogida responde 204"

$eviBody = @{
    recogidaId = $recCreada.id
    fotoUrl = "C:/tmp/evidencia-smoke.jpg"
    comentario = "Evidencia smoke test"
} | ConvertTo-Json

$eviResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias" -Method Post -Headers $headers -ContentType "application/json" -Body $eviBody -UseBasicParsing
Assert-True ($eviResp.StatusCode -eq 201) "Creacion de evidencia responde 201"

$eviCreada = $eviResp.Content | ConvertFrom-Json
Assert-True ($eviCreada.id -gt 0) "Evidencia creada con ID valido"

$evidenciasRecogidaResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/recogida/$($recCreada.id)" -Method Get -Headers $headers -UseBasicParsing
Assert-True ($evidenciasRecogidaResp.StatusCode -eq 200) "Consulta de evidencias por recogida responde 200"

$evidenciasRecogida = To-Array ($evidenciasRecogidaResp.Content | ConvertFrom-Json)
Assert-True ($null -ne $evidenciasRecogida) "Consulta de evidencias por recogida disponible"

$eviByIdResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/$($eviCreada.id)" -Method Get -Headers $headers -UseBasicParsing
Assert-True ($eviByIdResp.StatusCode -eq 200) "Consulta de evidencia por ID responde 200"

$eviById = $eviByIdResp.Content | ConvertFrom-Json
Assert-True ($eviById.id -eq $eviCreada.id) "Consulta por ID devuelve la evidencia creada"

$deleteEviResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/$($eviCreada.id)" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteEviResp.StatusCode -eq 204) "Eliminacion de evidencia responde 204"

$recogidas = To-Array ((Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Get -Headers $headers -UseBasicParsing).Content | ConvertFrom-Json)
Assert-True ($recogidas.Count -gt 0) "Listado de recogidas disponible"

$idEncontrado = $false
foreach ($r in $recogidas) {
    if ($r.id -eq $recCreada.id) {
        $idEncontrado = $true
        break
    }
}
Assert-True $idEncontrado "Recogida creada aparece en el listado"

$deleteRecResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas/$($recCreada.id)" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteRecResp.StatusCode -eq 204) "Eliminacion de recogida responde 204"

$deleteClienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes/$clienteId" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteClienteResp.StatusCode -eq 204) "Eliminacion de cliente de prueba responde 204"

# === Prueba de seguridad: Solo Administrador puede crear usuarios ===
$operadorEmail = "operador_test_$(Get-Random)@test.com"
$operadorPass = "OperadorTest123!"

# Registrar como Operador
$regBody = @{
    nombre = "Operador Test"
    correo = $operadorEmail
    password = $operadorPass
    rol = "Administrador"  # Intentamos registrar como Admin, pero backend debe forzar Operador
} | ConvertTo-Json

$regResp = Invoke-RestMethod -Uri "$BaseUrl/auth/register" -Method Post -ContentType "application/json" -Body $regBody
$operadorId = $regResp.usuario.id
$operadorToken = $regResp.token

# Login como Operador para obtener token fresco
$loginBody = @{ correo = $operadorEmail; password = $operadorPass } | ConvertTo-Json
$loginResp = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
$operadorToken = $loginResp.token

$operadorHeaders = @{ Authorization = "Bearer $operadorToken" }

# Operador intenta crear usuario (debe fallar con 403)
$crearUsuarioOperador = $false
try {
    $newUserBody = @{
        nombre = "Usuario Nuevo"
        correo = "user_test_$(Get-Random)@test.com"
        password = "User123!"
        rol = "Operador"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$BaseUrl/usuarios" -Method Post -ContentType "application/json" -Body $newUserBody -Headers $operadorHeaders | Out-Null
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        $crearUsuarioOperador = $true
    }
}
Assert-True $crearUsuarioOperador "Operador intenta crear usuario y recibe 403 (Forbidden)"

# Admin crea usuario exitosamente
$crearUsuarioAdmin = $false
try {
    $newUserBody = @{
        nombre = "Usuario Admin Created"
        correo = "admin_created_$(Get-Random)@test.com"
        password = "AdminUser123!"
        rol = "Operador"
    } | ConvertTo-Json
    
    $adminCreateResp = Invoke-RestMethod -Uri "$BaseUrl/usuarios" -Method Post -ContentType "application/json" -Body $newUserBody -Headers $headers
    $newUserId = $adminCreateResp.id
    $crearUsuarioAdmin = ($adminCreateResp.id -gt 0)
} catch {
    Write-Host "[DEBUG] Error al crear usuario con Admin: $_" -ForegroundColor Yellow
}
Assert-True $crearUsuarioAdmin "Admin crea usuario exitosamente (respuesta tiene ID)"

# === Prueba de permisos: Subadministrador con y sin ingresos ===
$subadminEmail = "subadmin_test_$(Get-Random)@test.com"
$subadminPass = "SubAdmin123!"
$subadminPermisos = @(
    "crear_recogidas",
    "cambiar_estado_recogidas",
    "subir_evidencias",
    "registrar_ingresos",
    "ver_ingresos"
)

$subadminBody = @{
    nombre = "Subadmin Test"
    correo = $subadminEmail
    password = $subadminPass
    rol = "Subadministrador"
    permisos = $subadminPermisos
} | ConvertTo-Json

$subadminCreateResp = Invoke-RestMethod -Uri "$BaseUrl/usuarios" -Method Post -ContentType "application/json" -Body $subadminBody -Headers $headers
$subadminId = $subadminCreateResp.id
Assert-True ($subadminId -gt 0) "Admin crea subadministrador con ID valido"
Assert-True ($subadminCreateResp.rol -eq "Subadministrador") "Subadministrador creado con rol correcto"

$subadminLoginBody = @{ correo = $subadminEmail; password = $subadminPass } | ConvertTo-Json
$subadminLoginResp = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $subadminLoginBody
$subadminHeaders = @{ Authorization = "Bearer $($subadminLoginResp.token)" }

$subClienteBody = @{
    nombre = "Cliente Subadmin $(Get-Date -Format yyyyMMddHHmmss)"
    telefono = "3007770000"
    direccion = "Direccion subadmin"
    ciudad = "Cali"
} | ConvertTo-Json

$subClienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes" -Method Post -Headers $subadminHeaders -ContentType "application/json" -Body $subClienteBody -UseBasicParsing
Assert-True ($subClienteResp.StatusCode -eq 201) "Subadministrador crea cliente de prueba"

$subCliente = $subClienteResp.Content | ConvertFrom-Json
$subClienteId = $subCliente.id
Assert-True ($subClienteId -gt 0) "Cliente de subadministrador creado con ID valido"

$subRecBody = @{
    clienteId = $subClienteId
    usuarioId = $subadminId
    estado = "Pendiente"
    cantidadPaquetes = 3
    observaciones = "Recogida creada por subadministrador"
    dineroRecibido = $false
    montoCobrado = $null
} | ConvertTo-Json

$subRecResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Post -Headers $subadminHeaders -ContentType "application/json" -Body $subRecBody -UseBasicParsing
Assert-True ($subRecResp.StatusCode -eq 201) "Subadministrador con permiso crea recogida"

$subRec = $subRecResp.Content | ConvertFrom-Json
$subRecId = $subRec.id
Assert-True ($subRecId -gt 0) "Recogida creada por subadministrador con ID valido"

$estadoConIngresoBody = @{
    estado = "Recogida"
    fotoUrl = "C:/tmp/evidencia-subadmin.jpg"
    comentario = "Cobro recibido de cliente"
    dineroRecibido = $true
    montoCobrado = 12500.50
    formaPago = "Efectivo"
} | ConvertTo-Json

$estadoConIngresoResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas/$subRecId/estado" -Method Put -Headers $subadminHeaders -ContentType "application/json" -Body $estadoConIngresoBody -UseBasicParsing
Assert-True ($estadoConIngresoResp.StatusCode -eq 200) "Subadministrador con permiso registra ingreso en recogida"

$estadoConIngreso = $estadoConIngresoResp.Content | ConvertFrom-Json
Assert-True ($estadoConIngreso.dineroRecibido -eq $true) "Respuesta confirma dinero recibido"
Assert-True ([decimal]$estadoConIngreso.montoCobrado -eq [decimal]12500.50) "Respuesta confirma monto cobrado"

$ingresosResp = Invoke-WebRequest -Uri "$BaseUrl/ingresos?cliente=Cliente%20Subadmin&operador=Subadmin%20Test" -Method Get -Headers $headers -UseBasicParsing
Assert-True ($ingresosResp.StatusCode -eq 200) "Consulta de historial de ingresos responde 200"

$ingresos = To-Array ($ingresosResp.Content | ConvertFrom-Json)
$ingresoEncontrado = $false
foreach ($ingreso in $ingresos) {
    if ($ingreso.recogidaId -eq $subRecId -and $ingreso.formaPago -eq 'Efectivo') {
        $ingresoEncontrado = $true
        break
    }
}
Assert-True $ingresoEncontrado "Historial de ingresos incluye el cobro registrado"

$subadminLiteEmail = "subadmin_lite_$(Get-Random)@test.com"
$subadminLitePass = "SubAdminLite123!"
$subadminLiteBody = @{
    nombre = "Subadmin Sin Ingresos"
    correo = $subadminLiteEmail
    password = $subadminLitePass
    rol = "Subadministrador"
    permisos = @(
        "crear_recogidas",
        "cambiar_estado_recogidas",
        "subir_evidencias"
    )
} | ConvertTo-Json

$subadminLiteCreateResp = Invoke-RestMethod -Uri "$BaseUrl/usuarios" -Method Post -ContentType "application/json" -Body $subadminLiteBody -Headers $headers
$subadminLiteId = $subadminLiteCreateResp.id
Assert-True ($subadminLiteId -gt 0) "Admin crea subadministrador sin permiso de ingresos"

$subadminLiteLoginBody = @{ correo = $subadminLiteEmail; password = $subadminLitePass } | ConvertTo-Json
$subadminLiteLoginResp = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $subadminLiteLoginBody
$subadminLiteHeaders = @{ Authorization = "Bearer $($subadminLiteLoginResp.token)" }

$subLiteClienteBody = @{
    nombre = "Cliente Subadmin Lite $(Get-Date -Format yyyyMMddHHmmss)"
    telefono = "3006660000"
    direccion = "Direccion subadmin lite"
    ciudad = "Barranquilla"
} | ConvertTo-Json

$subLiteClienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes" -Method Post -Headers $subadminLiteHeaders -ContentType "application/json" -Body $subLiteClienteBody -UseBasicParsing
$subLiteCliente = $subLiteClienteResp.Content | ConvertFrom-Json
$subLiteClienteId = $subLiteCliente.id

$subLiteRecBody = @{
    clienteId = $subLiteClienteId
    usuarioId = $subadminLiteId
    estado = "Pendiente"
    cantidadPaquetes = 1
    observaciones = "Recogida subadmin sin ingresos"
    dineroRecibido = $false
    montoCobrado = $null
} | ConvertTo-Json

$subLiteRecResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Post -Headers $subadminLiteHeaders -ContentType "application/json" -Body $subLiteRecBody -UseBasicParsing
$subLiteRec = $subLiteRecResp.Content | ConvertFrom-Json
$subLiteRecId = $subLiteRec.id

$ingresoSinPermisoBloqueado = $false
try {
    Invoke-RestMethod -Uri "$BaseUrl/recogidas/$subLiteRecId/estado" -Method Put -ContentType "application/json" -Body $estadoConIngresoBody -Headers $subadminLiteHeaders | Out-Null
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        $ingresoSinPermisoBloqueado = $true
    }
}
Assert-True $ingresoSinPermisoBloqueado "Subadministrador sin permiso de ingresos recibe 403 al registrar cobro"

# Limpiar usuarios de prueba
try {
    Invoke-WebRequest -Uri "$BaseUrl/recogidas/$subRecId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/clientes/$subClienteId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/recogidas/$subLiteRecId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/clientes/$subLiteClienteId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/usuarios/$operadorId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/usuarios/$newUserId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/usuarios/$subadminId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
    Invoke-WebRequest -Uri "$BaseUrl/usuarios/$subadminLiteId" -Method Delete -Headers $headers -UseBasicParsing | Out-Null
} catch { }

Write-Host "" 
Write-Host "Smoke test completado correctamente." -ForegroundColor Cyan
