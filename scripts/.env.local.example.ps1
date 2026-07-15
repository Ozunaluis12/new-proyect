# Copia este archivo como .env.local.ps1 y reemplaza los valores.
# Este archivo NO debe subirse al repositorio.
# Jwt__Key debe tener al menos 33 caracteres ASCII (recomendado 64).

$env:ConnectionStrings__DefaultConnection = 'Host=127.0.0.1;Port=5432;Database=loginova;Username=postgres;Password=postgres;Trust Server Certificate=true'
$env:Jwt__Key = 'REEMPLAZAR_CON_CLAVE_JWT_LARGA_DE_AL_MENOS_33_CARACTERES_1234567890'
$env:Jwt__Issuer = 'LoginovaAPI'
$env:Jwt__Audience = 'LoginovaClient'

# SMTP para el correo de recuperación de contraseña (Gmail/Google Workspace).
# 1) Activa la verificación en dos pasos en la cuenta de Gmail que va a enviar los correos.
# 2) Genera una "contraseña de aplicación" en https://myaccount.google.com/apppasswords
# 3) Usa esa contraseña de 16 caracteres aquí, NO la contraseña normal de la cuenta.
$env:Smtp__Host = 'smtp.gmail.com'
$env:Smtp__Port = '587'
$env:Smtp__EnableSsl = 'true'
$env:Smtp__User = 'REEMPLAZAR_CON_TU_CORREO@gmail.com'
$env:Smtp__Password = 'REEMPLAZAR_CON_CONTRASENA_DE_APLICACION'
$env:Smtp__From = 'REEMPLAZAR_CON_TU_CORREO@gmail.com'
