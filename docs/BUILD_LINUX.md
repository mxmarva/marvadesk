# Guía de compilación MarvaDesk en Linux

Esta guía detalla los requisitos y pasos para compilar MarvaDesk en Linux y generar paquetes `.deb`, `.rpm` o `.pkg.tar.zst` según tu distribución.

---

## 1. Verificar requisitos

Ejecuta el script de verificación desde la raíz del proyecto:

```bash
./scripts/check_linux_build_requirements.sh
```

Corrige cualquier requisito que aparezca como fallido antes de continuar.

---

## 2. Instalar dependencias por distribución

### Ubuntu / Debian

```bash
sudo apt install -y zip g++ gcc git curl wget nasm yasm libgtk-3-dev clang \
    libxcb-randr0-dev libxdo-dev libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev \
    libasound2-dev libpulse-dev cmake make libclang-dev ninja-build libssl-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpam0g-dev
```

**Para codec por hardware (`--hwcodec`):**
```bash
sudo apt install -y libva-dev
```

### Arch / Manjaro

```bash
sudo pacman -Syu --needed unzip git cmake gcc curl wget yasm nasm zip make pkg-config clang gtk3 xdotool libxcb libxfixes alsa-lib pipewire libva
```

### Fedora / CentOS / RHEL

```bash
sudo yum -y install gcc-c++ git curl wget nasm yasm gcc gtk3-devel clang libxcb-devel libxdo-devel libXfixes-devel pulseaudio-libs-devel cmake alsa-lib-devel gstreamer1-devel gstreamer1-plugins-base-devel pam-devel libva-devel
```

### openSUSE

```bash
sudo zypper install gcc-c++ git curl wget nasm yasm gcc gtk3-devel clang libxcb-devel libXfixes-devel cmake alsa-lib-devel gstreamer-devel gstreamer-plugins-base-devel xdotool-devel pam-devel libva-devel
```

---

## 3. Instalar Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

---

## 4. Instalar Flutter

Sigue la [guía oficial de Flutter para Linux](https://docs.flutter.dev/get-started/install/linux).

Verifica con:
```bash
flutter doctor -v
```

---

## 5. Instalar vcpkg y dependencias C++

```bash
git clone https://github.com/microsoft/vcpkg
cd vcpkg
git checkout 2023.04.15   # o la versión indicada en vcpkg.json
./bootstrap-vcpkg.sh
cd ..
export VCPKG_ROOT=$PWD/vcpkg   # o $HOME/vcpkg si lo clonaste ahí
$VCPKG_ROOT/vcpkg install libvpx libyuv opus aom
```

**Importante:** Añade `VCPKG_ROOT` a tu entorno de forma persistente (por ejemplo en `~/.bashrc`):
```bash
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.bashrc
source ~/.bashrc
```

---

## 6. Generar el bridge Flutter-Rust (obligatorio la primera vez)

El archivo `generated_bridge.dart` no está en el repositorio. Debes generarlo antes del build:

```bash
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs \
    --dart-output ./flutter/lib/generated_bridge.dart \
    --c-output ./flutter/macos/Runner/bridge_generated.h
cp ./flutter/macos/Runner/bridge_generated.h ./flutter/ios/Runner/bridge_generated.h
```

Luego, en el directorio `flutter`:
```bash
cd flutter
flutter pub get
cd ..
```

---

## 7. Inicializar submódulos

```bash
git submodule update --init --recursive
```

---

## 8. Ejecutar el build

Desde la **raíz del proyecto**:

### Build básico (genera .deb en Ubuntu/Debian)

```bash
python3 build.py --flutter
```

### Build con codec por hardware

```bash
python3 build.py --flutter --hwcodec
```

### Build con copiar/pegar de archivos en X11

```bash
python3 build.py --flutter --unix-file-copy-paste
```

### Combinar opciones

```bash
python3 build.py --flutter --hwcodec --unix-file-copy-paste
```

---

## 9. Salida del build

El formato de paquete depende de tu distribución:

| Distribución | Detecta | Salida |
|--------------|---------|--------|
| Ubuntu, Debian | `dpkg-deb` | `marvadesk-1.4.6.deb` |
| Arch, Manjaro | `pacman` | `rustdesk-1.4.6-manjaro-arch.pkg.tar.zst` |
| Fedora, CentOS | `yum` | `rustdesk-1.4.6-fedora28-centos8.rpm` |
| openSUSE | `zypper` | `rustdesk-1.4.6-suse.rpm` |

El paquete se genera en la **raíz del proyecto**.

---

## 10. Opciones de build.py

| Opción | Descripción |
|--------|-------------|
| `--flutter` | Compila la versión con UI Flutter (recomendado) |
| `--hwcodec` | Habilita codec por hardware (requiere libva-dev) |
| `--unix-file-copy-paste` | Soporte de copiar/pegar archivos en X11 |
| `--skip-cargo` | Omite la compilación Rust (solo Flutter; útil para iterar) |

---

## Solución de problemas

### "generated_bridge.dart not found"
Ejecuta el paso 6 (Generar el bridge Flutter-Rust).

### "VCPKG_ROOT not set"
```bash
export VCPKG_ROOT=/ruta/a/tu/vcpkg
```

### "openssl-sys" / "Could not find OpenSSL"
```bash
sudo apt install libssl-dev   # Ubuntu/Debian
# o: sudo dnf install openssl-devel   # Fedora
```

### "libva not found" con --hwcodec
```bash
sudo apt install libva-dev   # Ubuntu/Debian
```

### Error en vcpkg con libvpx (Fedora)
Consulta la sección "Fix libvpx (Fedora)" en el README principal.

### Flutter doctor muestra problemas
```bash
flutter doctor -v
flutter precache
```
