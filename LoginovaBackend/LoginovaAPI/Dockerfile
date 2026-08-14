# Etapa de compilación
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY LoginovaAPI.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Etapa de ejecución (imagen liviana, sin el SDK)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
# La imagen oficial trae un usuario "app" sin privilegios listo para usar;
# --chown lo deja como dueño de los archivos para que además pueda escribir
# en App_Data/uploads (el respaldo de disco local cuando R2 no está
# configurado) sin necesitar root.
COPY --from=build --chown=app:app /app/publish .
USER app

# Render inyecta el puerto real en la variable de entorno PORT.
ENV ASPNETCORE_ENVIRONMENT=Production
# Evita que .NET use inotify para vigilar cambios en appsettings.json en
# caliente: en producción la configuración real viene de variables de
# entorno, no del archivo, y contenedores chicos (como el free tier de
# Render) pueden agotar el límite de inotify del host y tumbar el arranque
# con "IOException: configured user limit (128) on inotify instances".
ENV DOTNET_hostBuilder__reloadConfigOnChange=false
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "ASPNETCORE_URLS=http://+:${PORT:-8080} dotnet LoginovaAPI.dll"]
