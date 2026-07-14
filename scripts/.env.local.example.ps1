# Copia este archivo como .env.local.ps1 y reemplaza los valores.
# Este archivo NO debe subirse al repositorio.
# Jwt__Key debe tener al menos 33 caracteres ASCII (recomendado 64).

$env:ConnectionStrings__DefaultConnection = 'Host=127.0.0.1;Port=5432;Database=loginova;Username=postgres;Password=postgres;Trust Server Certificate=true'
$env:Jwt__Key = 'REEMPLAZAR_CON_CLAVE_JWT_LARGA_DE_AL_MENOS_33_CARACTERES_1234567890'
$env:Jwt__Issuer = 'LoginovaAPI'
$env:Jwt__Audience = 'LoginovaClient'
