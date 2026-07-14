# Loginova

Loginova es una plataforma orientada a la gestión de logística y recolección de envíos. El proyecto centraliza la operación entre una aplicación móvil y un servicio backend, con el objetivo de ofrecer una experiencia ordenada para el registro, consulta y administración de la información del sistema.

## Descripción general

La solución está organizada como un monorepo que separa claramente la interfaz de usuario, la lógica de negocio y la capa de datos. Esta estructura facilita el mantenimiento, la evolución del producto y el trabajo coordinado entre frontend y backend.

## Composición del proyecto

- Frontend móvil en Flutter, ubicado en la carpeta Loginova.
- Backend en ASP.NET Core, ubicado en LoginovaBackend/LoginovaAPI.
- Base de datos relacional en PostgreSQL.
- Script de inicialización de base de datos en loginova_bd.sql.
- Workspace de Visual Studio Code para abrir todo el proyecto de forma integrada.

## Tecnologías utilizadas

- Flutter y Dart para la aplicación móvil.
- ASP.NET Core 10 para el servicio backend.
- Entity Framework Core para el acceso y manejo de datos.
- JWT para autenticación y control de sesiones.
- PostgreSQL como motor de base de datos.
- Npgsql como proveedor de conexión entre .NET y PostgreSQL.

## Base de datos

El sistema utiliza PostgreSQL como base de datos principal. Su estructura se encuentra respaldada por el archivo loginova_bd.sql, pensado para facilitar la creación e inicialización del esquema necesario para el funcionamiento de la aplicación.

## Organización general

El proyecto mantiene una separación clara entre presentación, lógica y persistencia. El frontend se encarga de la experiencia del usuario, mientras que el backend administra la autenticación, las reglas del negocio y el acceso a la información almacenada en PostgreSQL.

## Ejecución y validación

- Iniciar backend local: `./scripts/start-backend.ps1`
- Generar APK release: `./scripts/build-apk.ps1 -ApiBaseUrl http://127.0.0.1:5105/api`
- Ejecutar Flutter local (arranca backend si no está activo): `./scripts/run-local.ps1 -ApiBaseUrl http://127.0.0.1:5105/api`
- Ejecutar validación API+BD (CRUD principal): `./scripts/smoke-api.ps1`
- Verificar persistencia de base de datos: `./scripts/db_persistence_check.ps1`

Para celular físico en la misma red:
- Inicia el backend con `./scripts/start-backend.ps1`
- Construye el APK usando la IP de tu PC en la red local, por ejemplo:
  `./scripts/build-apk.ps1 -ApiBaseUrl http://192.168.1.50:5105/api`
- Si ejecutas en local en un dispositivo físico, usa también:
  `./scripts/run-local.ps1 -ApiBaseUrl http://192.168.1.50:5105/api`
- Asegura backend con configuración válida (`ConnectionStrings:DefaultConnection` y `Jwt:Key`), porque si faltan el backend no inicia y el login fallará.

> Nota: un APK instalado en el celular NO puede usar `http://127.0.0.1:5105/api` porque esa dirección apunta al propio teléfono, no a tu PC.

Archivo local recomendado para no repetir secretos:
- Copia `./scripts/.env.local.example.ps1` como `./scripts/.env.local.ps1` y completa valores.
- Luego ejecuta sin pasar secretos por comando:
	`./scripts/run-local.ps1 -ApiBaseUrl http://127.0.0.1:5105/api`
- Opcional: puedes usar otro archivo con `-EnvFile`, por ejemplo:
	`./scripts/run-local.ps1 -EnvFile ./scripts/mi-entorno.ps1 -ApiBaseUrl http://192.168.1.50:5105/api`

El smoke test valida autenticación, clientes, recogidas y evidencias con operaciones de creación, consulta, actualización y eliminación, incluyendo limpieza de datos de prueba.

## Propósito del proyecto

Loginova fue diseñado para servir como una solución de apoyo operativo en procesos de logística y recolección, priorizando una arquitectura moderna, modular y escalable.
