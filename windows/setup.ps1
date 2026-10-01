# setup.ps1 — Instala WSL + Ubuntu (y VS Code / Windows Terminal), luego
# ejecuta la configuración de Linux dentro de la distro.
#
# Uso (PowerShell como ADMINISTRADOR):
#   irm https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main/windows/setup.ps1 | iex
#
# Córrelo dos veces:
#   1a vez: instala WSL y Ubuntu -> reinicia Windows y abre Ubuntu para crear tu usuario
#   2a vez: detecta que Ubuntu ya existe y corre linux/setup.sh adentro

$Distro  = "Ubuntu-26.04"
$RepoRaw = "https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main"

$ErrorActionPreference = "Stop"

# --- Verificar administrador (usamos 'return' para no cerrar la ventana al correr con iex)
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Abre PowerShell como administrador y vuelve a correrlo." -ForegroundColor Red
    return
}

# --- Apps de Windows
Write-Host "`n==> Apps de Windows" -ForegroundColor Cyan
$apps = @("Microsoft.VisualStudioCode", "Microsoft.WindowsTerminal")
foreach ($app in $apps) {
    winget list --id $app -e *> $null
    if ($LASTEXITCODE -ne 0) {
        winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "    ok $app ya instalado" -ForegroundColor Green
    }
}

# --- WSL + distro
Write-Host "`n==> WSL" -ForegroundColor Cyan
# 'wsl --list' sale en UTF-16, por eso se limpian los caracteres nulos
$instaladas = (wsl.exe --list --quiet 2>$null) -replace "`0", "" |
    ForEach-Object { $_.Trim() } | Where-Object { $_ }

if ($instaladas -notcontains $Distro) {
    Write-Host "    Instalando WSL y $Distro..."
    wsl.exe --install -d $Distro
    Write-Host "`nSiguiente paso:" -ForegroundColor Yellow
    Write-Host "  1. Reinicia Windows (si te lo pide)."
    Write-Host "  2. Abre '$Distro' desde el menú inicio y crea tu usuario de Linux."
    Write-Host "  3. Vuelve a correr este mismo comando."
    return
}

wsl.exe --update
wsl.exe --set-default $Distro
Write-Host "    ok $Distro instalado y como distro por defecto" -ForegroundColor Green

# --- Configuración dentro de Linux
Write-Host "`n==> Configurando $Distro" -ForegroundColor Cyan
wsl.exe -d $Distro -- bash -c "bash <(curl -fsSL $RepoRaw/linux/setup.sh)"
