#!/usr/bin/env bash
# Generar paquetes desde Linux Mint (o cualquier distro):
#   .deb  → en tu máquina (sin Docker)
#   .rpm  → con Docker: imagen Fedora con TODO ya instalado (se construye 1 vez)
#   .pkg  → con Docker: imagen Arch con TODO ya instalado (se construye 1 vez)
#
# Uso:
#   ./scripts/build-packages.sh          # solo .deb
#   ./scripts/build-packages.sh deb      # solo .deb
#   ./scripts/build-packages.sh rpm      # .rpm (usa imagen marvadesk-builder-fedora; 1ª vez la construye)
#   ./scripts/build-packages.sh arch     # .pkg (usa imagen marvadesk-builder-arch; 1ª vez la construye)
#   ./scripts/build-packages.sh all      # deb + rpm + arch
#
# La PRIMERA vez que uses 'rpm' o 'arch' se construirá la imagen Docker (tarda ~20-40 min).
# Las siguientes veces solo se ejecuta el build (rápido).

set -e
cd "$(dirname "$0")/.."
SCRIPT_DIR="$(pwd)"
CONTAINER_ENGINE=""
command -v docker >/dev/null 2>&1 && CONTAINER_ENGINE=docker
command -v podman >/dev/null 2>&1 && [ -z "$CONTAINER_ENGINE" ] && CONTAINER_ENGINE=podman

BUILD_CMD="python3 build.py --flutter --unix-file-copy-paste"
IMAGE_FEDORA="marvadesk-builder-fedora"
IMAGE_ARCH="marvadesk-builder-arch"
IMAGE_FEDORA_PACKAGER="marvadesk-fedora-packager"
IMAGE_ARCH_PACKAGER="marvadesk-arch-packager"
BUNDLE_PATH="$SCRIPT_DIR/flutter/build/linux/x64/release/bundle"

get_version() {
  grep -E '^version\s*=' "$SCRIPT_DIR/Cargo.toml" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

usage() {
  echo "Uso: $0 [ deb | rpm | arch | rpm-from-bundle | arch-from-bundle | all ]"
  echo ""
  echo "  deb               - Genera .deb (en esta máquina)."
  echo "  rpm               - Genera .rpm compilando en contenedor Fedora (1ª vez: construye imagen)."
  echo "  arch              - Genera .pkg compilando en contenedor Arch (1ª vez: construye imagen)."
  echo "  rpm-from-bundle   - Genera .rpm solo empaquetando el bundle ya compilado (sin Flutter/Rust)."
  echo "  arch-from-bundle  - Genera .pkg solo empaquetando el bundle ya compilado (sin Flutter/Rust)."
  echo "  all               - deb + rpm + arch."
  echo ""
  echo "Para rpm-from-bundle y arch-from-bundle necesitas el bundle en: $BUNDLE_PATH"
  echo "  (ejecuta antes: python3 build.py --flutter)"
}

run_deb() {
  echo "==> Generando .deb (en esta máquina)..."
  $BUILD_CMD
  echo "==> Listo. Busca marvadesk-*.deb en la raíz del proyecto."
}

run_rpm() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Se necesita Docker o Podman: sudo apt install docker.io"
    exit 1
  fi
  if ! $CONTAINER_ENGINE image inspect "$IMAGE_FEDORA" >/dev/null 2>&1; then
    echo "==> Primera vez: construyendo imagen $IMAGE_FEDORA (puede tardar 20-40 min)..."
    $CONTAINER_ENGINE build -f "$SCRIPT_DIR/docker/Dockerfile.fedora" -t "$IMAGE_FEDORA" "$SCRIPT_DIR"
  fi
  echo "==> Generando .rpm..."
  $CONTAINER_ENGINE run --rm \
    -v "$SCRIPT_DIR:/workspace:rw" \
    -w /workspace \
    -e VCPKG_ROOT=/vcpkg \
    "$IMAGE_FEDORA"
  echo "==> Listo. Busca rustdesk-*-fedora*.rpm en la raíz del proyecto."
}

run_arch() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Se necesita Docker o Podman: sudo apt install docker.io"
    exit 1
  fi
  if ! $CONTAINER_ENGINE image inspect "$IMAGE_ARCH" >/dev/null 2>&1; then
    echo "==> Primera vez: construyendo imagen $IMAGE_ARCH (puede tardar 20-40 min)..."
    $CONTAINER_ENGINE build -f "$SCRIPT_DIR/docker/Dockerfile.arch" -t "$IMAGE_ARCH" "$SCRIPT_DIR"
  fi
  echo "==> Generando .pkg.tar.zst..."
  $CONTAINER_ENGINE run --rm \
    -v "$SCRIPT_DIR:/workspace:rw" \
    -w /workspace \
    -e VCPKG_ROOT=/vcpkg \
    "$IMAGE_ARCH"
  echo "==> Listo. Busca rustdesk-*-manjaro-arch.pkg.tar.zst en la raíz del proyecto."
}

run_rpm_from_bundle() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Se necesita Docker o Podman: sudo apt install docker.io"
    exit 1
  fi
  if [ ! -d "$BUNDLE_PATH" ] || [ ! -f "$BUNDLE_PATH/marvadesk" ]; then
    echo "No se encuentra el bundle en $BUNDLE_PATH (o no existe el ejecutable marvadesk)."
    echo "Compila antes: python3 build.py --flutter"
    exit 1
  fi
  VER="$(get_version)"
  if ! $CONTAINER_ENGINE image inspect "$IMAGE_FEDORA_PACKAGER" >/dev/null 2>&1; then
    echo "==> Construyendo imagen mínima $IMAGE_FEDORA_PACKAGER (solo rpm-build; ~1 min)..."
    $CONTAINER_ENGINE build -f "$SCRIPT_DIR/docker/Dockerfile.fedora-packager" -t "$IMAGE_FEDORA_PACKAGER" "$SCRIPT_DIR"
  fi
  echo "==> Generando .rpm desde el bundle (sin compilar)..."
  $CONTAINER_ENGINE run --rm \
    -v "$SCRIPT_DIR:/workspace:rw" \
    -w /workspace \
    -e HBB=/workspace \
    "$IMAGE_FEDORA_PACKAGER" \
    bash -c "sed -i \"s/^Version:.*/Version:    $VER/\" /workspace/res/rpm-flutter.spec && rpmbuild -ba -D \"HBB /workspace\" /workspace/res/rpm-flutter.spec && cp /root/rpmbuild/RPMS/x86_64/*.rpm /workspace/"
  echo "==> Listo. Busca rustdesk-*-*.rpm en la raíz del proyecto."
}

run_arch_from_bundle() {
  if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Se necesita Docker o Podman: sudo apt install docker.io"
    exit 1
  fi
  if [ ! -d "$BUNDLE_PATH" ] || [ ! -f "$BUNDLE_PATH/marvadesk" ]; then
    echo "No se encuentra el bundle en $BUNDLE_PATH (o no existe el ejecutable marvadesk)."
    echo "Compila antes: python3 build.py --flutter"
    exit 1
  fi
  VER="$(get_version)"
  if ! $CONTAINER_ENGINE image inspect "$IMAGE_ARCH_PACKAGER" >/dev/null 2>&1; then
    echo "==> Construyendo imagen mínima $IMAGE_ARCH_PACKAGER (solo base-devel; ~2-5 min)..."
    $CONTAINER_ENGINE build -f "$SCRIPT_DIR/docker/Dockerfile.arch-packager" -t "$IMAGE_ARCH_PACKAGER" "$SCRIPT_DIR"
  fi
  echo "==> Generando .pkg desde el bundle (sin compilar)..."
  HOST_UID=$(stat -c %u "$SCRIPT_DIR")
  HOST_GID=$(stat -c %g "$SCRIPT_DIR")
  $CONTAINER_ENGINE run --rm \
    -v "$SCRIPT_DIR:/workspace:rw" \
    -w /workspace/res \
    -e HBB=/workspace \
    -e FLUTTER=1 \
    -e HOME=/tmp \
    --user "$HOST_UID:$HOST_GID" \
    "$IMAGE_ARCH_PACKAGER" \
    bash -c "sed -i \"s/^pkgver=.*/pkgver=$VER/\" /workspace/res/PKGBUILD && HBB=/workspace FLUTTER=1 makepkg -f --nodeps && for f in marvadesk-*.pkg.tar.zst; do [[ \"\$f\" == *-debug-* ]] && continue; cp \"\$f\" /workspace/; done"
  rm -f "$SCRIPT_DIR"/rustdesk-*.pkg.tar.zst "$SCRIPT_DIR"/*-debug-*.pkg.tar.zst
  echo "==> Listo. Busca marvadesk-*-*.pkg.tar.zst en la raíz del proyecto."
}

case "${1:-deb}" in
  deb)   run_deb ;;
  rpm)   run_rpm ;;
  arch)  run_arch ;;
  rpm-from-bundle)  run_rpm_from_bundle ;;
  arch-from-bundle) run_arch_from_bundle ;;
  all)   run_deb; run_rpm; run_arch ;;
  -h|--help) usage; exit 0 ;;
  *)     echo "Opción no válida: $1"; usage; exit 1 ;;
esac
