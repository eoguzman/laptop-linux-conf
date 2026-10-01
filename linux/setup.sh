#!/usr/bin/env bash
# Configura una instalación nueva de Ubuntu (WSL) para desarrollo:
# paquetes base, git, llave SSH para GitHub, GitHub CLI y Claude Code.
# Es idempotente: puedes correrlo varias veces sin romper nada.
#
# Uso:
#   bash <(curl -fsSL https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main/linux/setup.sh)
# Pregunta nombre y correo para git si no están configurados.

set -euo pipefail

GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
SSH_KEY="$HOME/.ssh/id_ed25519"
REPO_RAW="https://raw.githubusercontent.com/eoguzman/laptop-linux-conf/main"

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    ✓ %s\033[0m\n' "$*"; }
aviso(){ printf '\033[1;33m    ! %s\033[0m\n' "$*"; }
preguntar() { local v; read -rp "    $1: " v </dev/tty; printf -v "$2" '%s' "$v"; }

# ---------------------------------------------------------------- 1. Paquetes
paso "Actualizando paquetes"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install -y git curl wget unzip build-essential openssh-client ca-certificates
ok "Paquetes base instalados"

# ---------------------------------------------------------------- 1b. .bashrc
paso "Instalando .bashrc del repo"
tmp_bashrc="$(mktemp)"
curl -fsSL "$REPO_RAW/.bashrc" -o "$tmp_bashrc"
if [[ -f ~/.bashrc ]] && cmp -s "$tmp_bashrc" ~/.bashrc; then
  ok ".bashrc ya está actualizado"
else
  if [[ -f ~/.bashrc ]]; then
    respaldo="$HOME/.bashrc.bak-$(date +%Y%m%d-%H%M%S)"
    cp ~/.bashrc "$respaldo"
    ok "Respaldo del anterior en $respaldo"
  fi
  cp "$tmp_bashrc" ~/.bashrc
  ok ".bashrc instalado"
fi
rm -f "$tmp_bashrc"

# ---------------------------------------------------------------- 2. Git
paso "Configurando git"
if [[ -z "$GIT_NAME"  ]]; then GIT_NAME="$(git config --global user.name  || true)"; fi
if [[ -z "$GIT_EMAIL" ]]; then GIT_EMAIL="$(git config --global user.email || true)"; fi
if [[ -z "$GIT_NAME"  ]]; then preguntar "Tu nombre para git" GIT_NAME; fi
if [[ -z "$GIT_EMAIL" ]]; then preguntar "Tu correo de GitHub" GIT_EMAIL; fi

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.autocrlf input
if command -v code >/dev/null; then
  git config --global core.editor "code --wait"
fi
ok "git listo: $GIT_NAME <$GIT_EMAIL>"

# ---------------------------------------------------------------- 3. SSH
paso "Llave SSH"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [[ ! -f "$SSH_KEY" ]]; then
  echo "    (Enter dos veces si no quieres passphrase)"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
  ok "Llave creada en $SSH_KEY"
else
  ok "Ya existe $SSH_KEY, la reutilizo"
fi
# Registrar github.com como host conocido para evitar la pregunta "Are you sure...?"
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
  ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
fi

# ---------------------------------------------------------------- 4. GitHub CLI
paso "GitHub CLI (para subir la llave SSH automáticamente)"
if ! command -v gh >/dev/null; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
fi
ok "gh instalado"

if ! gh auth status >/dev/null 2>&1; then
  echo "    Copia el código que aparece y pégalo en https://github.com/login/device"
  gh auth login --hostname github.com --git-protocol ssh --web \
    --skip-ssh-key --scopes admin:public_key
fi

if gh ssh-key add "$SSH_KEY.pub" --title "$(hostname)-wsl" 2>/tmp/gh-ssh.err; then
  ok "Llave subida a GitHub como $(hostname)-wsl"
elif grep -qi "already" /tmp/gh-ssh.err; then
  ok "La llave ya estaba registrada en GitHub"
else
  aviso "No pude subir la llave: $(cat /tmp/gh-ssh.err)"
fi

salida="$(ssh -T git@github.com 2>&1 || true)"
if [[ "$salida" == *"successfully authenticated"* ]]; then
  ok "SSH con GitHub funciona"
else
  aviso "La prueba SSH falló: $salida"
fi

# ---------------------------------------------------------------- 5. Claude Code
paso "Claude Code"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
if ! grep -q 'HOME/.local/bin' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
ok "Claude Code instalado ($(claude --version 2>/dev/null || echo 'reinicia la terminal'))"

# ---------------------------------------------------------------- Fin
paso "Todo listo"
echo "    Corre:  source ~/.bashrc   y luego   claude   para iniciar sesión."
