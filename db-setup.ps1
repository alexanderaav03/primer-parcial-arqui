# db-setup.ps1
# Lee DATABASE_URL desde ms-ejercicios\.env y ms-rutinas\.env,
# y crea/elimina esas bases con createdb.exe / dropdb.exe directo.
#
# Uso:
#   .\db-setup.ps1 crear
#   .\db-setup.ps1 eliminar
#   .\db-setup.ps1 reset

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("crear", "eliminar", "reset")]
    [string]$accion
)

$ErrorActionPreference = "Stop"

$PGBIN = "C:\Program Files\PostgreSQL\16\bin"
$ScriptRoot = $PSScriptRoot

$Servicios = @(
    @{ Nombre = "ms-ejercicios"; EnvPath = Join-Path $ScriptRoot "ms-ejercicios\.env" },
    @{ Nombre = "ms-rutinas";    EnvPath = Join-Path $ScriptRoot "ms-rutinas\.env" }
)

function Get-DbInfoFromEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "  No se encontro el archivo: $Path" -ForegroundColor Red
        return $null
    }

    $line = Get-Content -Path $Path -Encoding utf8 | Where-Object { $_ -match "^DATABASE_URL=" }
    if (-not $line) {
        Write-Host "  No se encontro DATABASE_URL en $Path" -ForegroundColor Red
        return $null
    }

    # postgresql://user:password@host:port/dbname
    $url = $line -replace "^DATABASE_URL=", ""
    if ($url -match "postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)$") {
        return @{
            User = $Matches[1]
            Pass = $Matches[2]
            Host = $Matches[3]
            Port = $Matches[4]
            Db   = $Matches[5]
        }
    } else {
        Write-Host "  No se pudo parsear DATABASE_URL: $url" -ForegroundColor Red
        return $null
    }
}

function Crear-DB {
    param($info)
    $env:PGPASSWORD = $info.Pass
    Write-Host "Creando base '$($info.Db)'..." -ForegroundColor Cyan
    & "$PGBIN\createdb.exe" -U $info.User -h $info.Host -p $info.Port $info.Db
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: '$($info.Db)' creada." -ForegroundColor Green
    } else {
        Write-Host "  Aviso: '$($info.Db)' ya existia o hubo un error." -ForegroundColor Yellow
    }
}

function Eliminar-DB {
    param($info)
    $env:PGPASSWORD = $info.Pass
    Write-Host "Eliminando base '$($info.Db)'..." -ForegroundColor Cyan
    & "$PGBIN\dropdb.exe" -U $info.User -h $info.Host -p $info.Port --if-exists $info.Db
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: '$($info.Db)' eliminada (o no existia)." -ForegroundColor Green
    } else {
        Write-Host "  Error eliminando '$($info.Db)' (¿hay conexiones activas? cierra uvicorn primero)." -ForegroundColor Red
    }
}

foreach ($servicio in $Servicios) {
    Write-Host "`n--- $($servicio.Nombre) ---" -ForegroundColor Magenta
    $info = Get-DbInfoFromEnv -Path $servicio.EnvPath
    if (-not $info) { continue }

    switch ($accion) {
        "crear"    { Crear-DB $info }
        "eliminar" { Eliminar-DB $info }
        "reset"    { Eliminar-DB $info; Crear-DB $info }
    }
}

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
Write-Host "`nListo." -ForegroundColor Cyan
