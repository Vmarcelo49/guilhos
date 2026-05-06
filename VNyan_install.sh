#!/usr/bin/env bash

set -euo pipefail

# ============================================
# VNyan Linux Installer
# Portable + Proton GE
# ============================================

VNYAN_VERSION="1.6.8b"
PROTON_VERSION="GE-Proton10-34"

# Troque pela sua release
VNYAN_ZIP_URL="https://pixeldrain.com/api/file/U5vVcdvg?download"

PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz"

PROTON_BASE_DIR="$HOME/.local/share/vnyan-installer/proton"
PROTON_DIR="${PROTON_BASE_DIR}/${PROTON_VERSION}"

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
    --title="Escolha a pasta de instalação do VNyan")

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
# Baixar Proton GE
# ============================================

mkdir -p "$PROTON_BASE_DIR"

if [[ ! -d "$PROTON_DIR" ]]; then
    echo
    echo "Baixando Proton GE ${PROTON_VERSION}..."

    PROTON_ARCHIVE="${DOWNLOADS_DIR}/${PROTON_VERSION}.tar.gz"

    curl -L "$PROTON_URL" -o "$PROTON_ARCHIVE"

    echo "Extraindo Proton GE..."

    tar -xzf "$PROTON_ARCHIVE" -C "$PROTON_BASE_DIR"
else
    echo
    echo "Proton GE já instalado."
fi

PROTON_BIN="${PROTON_DIR}/proton"

if [[ ! -f "$PROTON_BIN" ]]; then
    echo "Erro: Proton não encontrado."
    exit 1
fi

# ============================================
# Criar Wine Prefix
# ============================================

echo
echo "Criando Wine prefix..."

export WINEPREFIX="$PREFIX_DIR"

"$PROTON_BIN" run wineboot || true

# ============================================
# Baixar VNyan
# ============================================

echo
echo "Baixando VNyan ${VNYAN_VERSION}..."

VNYAN_ZIP="${DOWNLOADS_DIR}/vnyan.zip"

curl -L "$VNYAN_ZIP_URL" -o "$VNYAN_ZIP"

echo
echo "Extraindo VNyan..."

unzip -o "$VNYAN_ZIP" -d "$APP_DIR"

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

export WINEPREFIX="${PREFIX_DIR}"

# AMD Vulkan optimizations
export RADV_PERFTEST=gpl

cd "\$(dirname "${VNYAN_EXE}")"

exec "${PROTON_BIN}" run "${VNYAN_EXE}" -portable &> "${INSTALL_DIR}/vnyan.log"
EOF

chmod +x "$LAUNCHER_PATH"

# ============================================
# Desktop Entry
# ============================================

DESKTOP_FILE="$HOME/Desktop/VNyan.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=VNyan
Exec=${LAUNCHER_PATH}
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
