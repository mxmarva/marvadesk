#!/usr/bin/env bash
# Script de verificación de requisitos para compilar MarvaDesk en Linux
# Ejecutar desde la raíz del proyecto: ./scripts/check_linux_build_requirements.sh

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() { echo -e "${GREEN}✓${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; return 1; }
check_warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "=========================================="
echo "  Verificación de requisitos MarvaDesk"
echo "  (Build Linux - Flutter + .deb)"
echo "=========================================="
echo ""

ERRORS=0

# 1. Herramientas básicas
echo "--- Herramientas de compilación ---"
command -v gcc >/dev/null 2>&1 && check_ok "gcc" || { check_fail "gcc (instalar: build-essential)"; ERRORS=$((ERRORS+1)); }
command -v g++ >/dev/null 2>&1 && check_ok "g++" || { check_fail "g++ (instalar: build-essential)"; ERRORS=$((ERRORS+1)); }
command -v make >/dev/null 2>&1 && check_ok "make" || { check_fail "make"; ERRORS=$((ERRORS+1)); }
command -v cmake >/dev/null 2>&1 && check_ok "cmake" || { check_fail "cmake"; ERRORS=$((ERRORS+1)); }
command -v clang >/dev/null 2>&1 && check_ok "clang" || check_warn "clang (recomendado)"
command -v ninja >/dev/null 2>&1 && check_ok "ninja-build" || { check_fail "ninja-build"; ERRORS=$((ERRORS+1)); }
command -v nasm >/dev/null 2>&1 && check_ok "nasm" || { check_fail "nasm"; ERRORS=$((ERRORS+1)); }
command -v pkg-config >/dev/null 2>&1 && check_ok "pkg-config" || { check_fail "pkg-config"; ERRORS=$((ERRORS+1)); }
echo ""

# 2. Dependencias de sistema (GTK, X11, audio, etc.)
echo "--- Bibliotecas de desarrollo ---"
pkg-config --exists gtk+-3.0 2>/dev/null && check_ok "libgtk-3-dev" || { check_fail "libgtk-3-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists xcb-randr 2>/dev/null && check_ok "libxcb-randr0-dev" || { check_fail "libxcb-randr0-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists xfixes 2>/dev/null && check_ok "libxfixes-dev" || { check_fail "libxfixes-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists xcb-shape 2>/dev/null && check_ok "libxcb-shape0-dev" || { check_fail "libxcb-shape0-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists xcb-xfixes 2>/dev/null && check_ok "libxcb-xfixes0-dev" || { check_fail "libxcb-xfixes0-dev"; ERRORS=$((ERRORS+1)); }
# libxdo: puede ser libxdo3 o libxdo4
(ldconfig -p 2>/dev/null | grep -q libxdo || pkg-config --exists xdo 2>/dev/null) && check_ok "libxdo-dev" || { check_fail "libxdo-dev"; ERRORS=$((ERRORS+1)); }
(ldconfig -p 2>/dev/null | grep -q libasound || pkg-config --exists alsa 2>/dev/null) && check_ok "libasound2-dev" || { check_fail "libasound2-dev"; ERRORS=$((ERRORS+1)); }
[ -f /usr/include/security/pam_appl.h ] 2>/dev/null && check_ok "libpam0g-dev" || { check_fail "libpam0g-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists gstreamer-1.0 2>/dev/null && check_ok "libgstreamer1.0-dev" || { check_fail "libgstreamer1.0-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists gstreamer-plugins-base-1.0 2>/dev/null && check_ok "libgstreamer-plugins-base1.0-dev" || { check_fail "libgstreamer-plugins-base1.0-dev"; ERRORS=$((ERRORS+1)); }
pkg-config --exists openssl 2>/dev/null && check_ok "libssl-dev" || { check_fail "libssl-dev (openssl-sys lo requiere)"; ERRORS=$((ERRORS+1)); }
echo ""

# 3. libva (para --hwcodec)
echo "--- Codec hardware (opcional, para --hwcodec) ---"
ldconfig -p 2>/dev/null | grep -q libva && check_ok "libva-dev" || check_warn "libva-dev (opcional, para codec por hardware)"
echo ""

# 4. Rust
echo "--- Rust ---"
if command -v rustc >/dev/null 2>&1; then
    RUST_VER=$(rustc --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [[ "$RUST_VER" == "1.75" ]] || [[ "$RUST_VER" > "1.75" ]]; then
        check_ok "rustc $RUST_VER"
    else
        check_warn "rustc $RUST_VER (se recomienda 1.75+)"
    fi
else
    check_fail "Rust (ejecutar: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)"
    ERRORS=$((ERRORS+1))
fi
command -v cargo >/dev/null 2>&1 && check_ok "cargo" || { check_fail "cargo"; ERRORS=$((ERRORS+1)); }
echo ""

# 5. Flutter
echo "--- Flutter ---"
if command -v flutter >/dev/null 2>&1; then
    check_ok "flutter ($(flutter --version 2>/dev/null | head -1))"
    flutter doctor -v 2>/dev/null | grep -q "Linux" && check_ok "Flutter Linux support" || check_warn "Verificar: flutter doctor -v"
else
    check_fail "Flutter (https://docs.flutter.dev/get-started/install/linux)"
    ERRORS=$((ERRORS+1))
fi
echo ""

# 6. flutter_rust_bridge_codegen
echo "--- Flutter Rust Bridge ---"
if command -v flutter_rust_bridge_codegen >/dev/null 2>&1 || [ -f ~/.cargo/bin/flutter_rust_bridge_codegen ]; then
    check_ok "flutter_rust_bridge_codegen"
else
    check_warn "flutter_rust_bridge_codegen (instalar: cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid)"
fi
echo ""

# 7. vcpkg
echo "--- vcpkg ---"
if [ -n "$VCPKG_ROOT" ] && [ -f "$VCPKG_ROOT/vcpkg" ]; then
    check_ok "VCPKG_ROOT=$VCPKG_ROOT"
    if [ -d "$VCPKG_ROOT/installed" ]; then
        check_ok "vcpkg instalado (libvpx, libyuv, opus, aom)"
    else
        check_warn "Ejecutar: \$VCPKG_ROOT/vcpkg install libvpx libyuv opus aom"
    fi
else
    check_fail "VCPKG_ROOT no configurado o vcpkg no encontrado"
    echo "  Instalar: git clone https://github.com/microsoft/vcpkg && cd vcpkg && ./bootstrap-vcpkg.sh"
    echo "  Luego: export VCPKG_ROOT=\$HOME/vcpkg"
    echo "  Y: \$VCPKG_ROOT/vcpkg install libvpx libyuv opus aom"
    ERRORS=$((ERRORS+1))
fi
echo ""

# 8. dpkg (para .deb en Ubuntu/Debian)
echo "--- Empaquetado .deb ---"
if command -v dpkg-deb >/dev/null 2>&1; then
    check_ok "dpkg-deb (generará .deb)"
elif [ -f /usr/bin/pacman ]; then
    check_ok "pacman (generará .pkg.tar.zst para Arch/Manjaro)"
elif command -v rpmbuild >/dev/null 2>&1; then
    check_ok "rpmbuild (generará .rpm para Fedora/SUSE)"
else
    check_warn "No se detectó dpkg/pacman/rpm - el empaquetado puede fallar"
fi
echo ""

# 9. Python
echo "--- Python ---"
command -v python3 >/dev/null 2>&1 && check_ok "python3" || { check_fail "python3"; ERRORS=$((ERRORS+1)); }
echo ""

# 10. Bridge generado (requerido para Flutter)
echo "--- Archivos generados ---"
if [ -f flutter/lib/generated_bridge.dart ]; then
    check_ok "generated_bridge.dart (bridge Flutter-Rust)"
else
    check_warn "generated_bridge.dart no existe. Ejecutar antes: ~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h"
fi
echo ""

# 11. Submódulos
echo "--- Submódulos git ---"
if [ -d .git ] && [ -f .gitmodules ] 2>/dev/null; then
    if git submodule status 2>/dev/null | grep -q "^\-"; then
        check_warn "Submódulos no inicializados. Ejecutar: git submodule update --init --recursive"
    else
        check_ok "Submódulos inicializados"
    fi
fi
echo ""

# Resumen
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}Requisitos cumplidos. Puedes ejecutar el build.${NC}"
else
    echo -e "${RED}Hay $ERRORS requisito(s) pendiente(s).${NC}"
fi
echo "=========================================="
exit $ERRORS
