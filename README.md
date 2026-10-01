# laptop-linux-conf

Configuración automática de una máquina nueva: WSL + Ubuntu, git, llave SSH para GitHub, GitHub CLI y Claude Code.

## Máquina Windows nueva

En PowerShell **como administrador**:

```powershell
irm https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main/windows/setup.ps1 | iex
```

La primera vez instala WSL y pide reiniciar. Abre Ubuntu, crea tu usuario y corre el mismo comando otra vez.

## Solo la parte de Linux (WSL ya instalado, o cualquier Ubuntu/Debian)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main/linux/setup.sh)
```

El script te pregunta tu nombre y correo para git.

## Qué hace

- `windows/setup.ps1`: instala VS Code, Windows Terminal, WSL y la distro; luego lanza `linux/setup.sh` dentro de ella.
- `.bashrc`: mi configuración de bash; `setup.sh` la instala y respalda la anterior como `~/.bashrc.bak-FECHA`.
- `linux/setup.sh`: actualiza paquetes, instala el `.bashrc` del repo, configura git, crea la llave SSH, la sube a GitHub con `gh` y prueba la conexión, e instala Claude Code.

Ambos scripts se pueden correr varias veces sin problema.
