#!/usr/bin/env bash

set -euo pipefail

# ============================================
# VNyan Linux Installer
# Portable + Proton (Steam)
# ============================================

VNYAN_VERSION="1.6.8b"

# Troque pela sua release
VNYAN_ZIP_URL="https://pixeldrain.com/api/file/U5vVcdvg?download"

# ============================================
# Dependências
# ============================================

require_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Erro: comando '$1' não encontrado."
        exit 1
    fi
}

require_command zenity
require_command curl
require_command tar
require_command unzip
require_command xdg-user-dir

# ============================================
# Introdução
# ============================================

echo
echo "VNyan ${VNYAN_VERSION} será instalado."
echo
echo "Pressione ENTER para escolher a pasta de instalação."
read -r

# ============================================
# Escolha da pasta
# ============================================

INSTALL_DIR=$(zenity --file-selection --directory \
    --title="Escolha a pasta de instalação do VNyan" 2>/dev/null)

if [[ -z "${INSTALL_DIR}" ]]; then
    echo "Instalação cancelada."
    exit 1
fi

INSTALL_DIR="${INSTALL_DIR}/VNyan"

APP_DIR="${INSTALL_DIR}/app"
PREFIX_DIR="${INSTALL_DIR}/prefix"
DOWNLOADS_DIR="${INSTALL_DIR}/downloads"

mkdir -p "$APP_DIR"
mkdir -p "$PREFIX_DIR"
mkdir -p "$DOWNLOADS_DIR"

# ============================================
# Procurar Proton instalado na Steam
# ============================================

echo
echo "Procurando Proton instalado..."

mapfile -t FOUND_PROTONS < <(
    find ~/.steam ~/.local/share/Steam \
        -type f -name proton 2>/dev/null
)

if [[ ${#FOUND_PROTONS[@]} -gt 0 ]]; then
    PROTON_BIN="${FOUND_PROTONS[0]}"
    echo
    echo "Proton encontrado:"
    echo "$PROTON_BIN"
else
    echo
    echo "Nenhum Proton encontrado."
    echo "Instale qualquer proton na Steam e tente novamente."
    exit 1
fi

# ============================================
# Criar Wine Prefix (compatdata)
# ============================================

echo
echo "Criando Wine prefix (compatdata)..."

export STEAM_COMPAT_DATA_PATH="${PREFIX_DIR}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH=$(dirname $(dirname "$PROTON_BIN"))

mkdir -p "${PREFIX_DIR}/pfx"

"$PROTON_BIN" run wineboot || true

# ============================================
# Baixar VNyan
# ============================================

echo
echo "Baixando VNyan ${VNYAN_VERSION}..."

VNYAN_ZIP="${DOWNLOADS_DIR}/vnyan.zip"

if [[ -f "$VNYAN_ZIP" ]]; then
    echo "ZIP do VNyan já existe, pulando download."
else
    curl -L "$VNYAN_ZIP_URL" -o "$VNYAN_ZIP"
fi

echo
echo "Extraindo VNyan..."

unzip -o "$VNYAN_ZIP" -d "$APP_DIR"
unzip -o "$APP_DIR/linux-fixes.zip" -d "$APP_DIR"

# ============================================
# Detectar executável
# ============================================

VNYAN_EXE=$(find "$APP_DIR" -iname "VNyan.exe" | head -n 1)

if [[ -z "${VNYAN_EXE}" ]]; then
    echo "Erro: VNyan.exe não encontrado."
    exit 1
fi

# ============================================
# Criar launcher
# ============================================

LAUNCHER_PATH="${INSTALL_DIR}/launcher.sh"

cat > "$LAUNCHER_PATH" <<EOF
#!/usr/bin/env bash

export STEAM_COMPAT_DATA_PATH="${PREFIX_DIR}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$(dirname $(dirname "$PROTON_BIN"))"

# AMD Vulkan optimizations
export RADV_PERFTEST=gpl

cd "\$(dirname "${VNYAN_EXE}")"

exec "${PROTON_BIN}" run "${VNYAN_EXE}" -portable &> "${INSTALL_DIR}/vnyan.log"
EOF

chmod +x "$LAUNCHER_PATH"

# ============================================
# Desktop Entry
# ============================================

DESKTOP_DIR=$(xdg-user-dir DESKTOP)

if [[ ! -d "$DESKTOP_DIR" ]]; then
    echo "Pasta Desktop não encontrada."
    exit 1
fi

DESKTOP_FILE="${DESKTOP_DIR}/VNyan.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=VNyan
Exec=\"${LAUNCHER_PATH}\"
Type=Application
Categories=Game;
StartupNotify=true
Terminal=false
EOF

chmod +x "$DESKTOP_FILE"

# ============================================
# Final
# ============================================

echo
echo "============================================"
echo "Instalação concluída."
echo "============================================"
echo
echo "Pasta:"
echo "$INSTALL_DIR"
echo
echo "Launcher:"
echo "$LAUNCHER_PATH"
echo
echo "Atalho:"
echo "$DESKTOP_FILE"
echo
echo "Logs:"
echo "${INSTALL_DIR}/vnyan.log"
echo
echo "Agora execute o atalho da área de trabalho."
echo
