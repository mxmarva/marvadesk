# MarvaDesk

<p align="center">
  <strong>MarvaDesk</strong> — Remote Desktop<br>
  <a href="#raw-steps-to-build">Build</a> •
  <a href="#how-to-build-with-docker">Docker</a> •
  <a href="#file-structure">Structure</a> •
  <a href="#screenshots">Screenshots</a>
</p>

---

Solución de escritorio remoto escrita en Rust. Funciona sin configuración previa. Tienes control total de tus datos. Puedes usar tu propio servidor de encuentro/relé o implementar el tuyo.

> **Aviso:** Los desarrolladores de MarvaDesk no respaldan el uso ilegal o no ético de este software. El acceso no autorizado, el control remoto sin permiso o la invasión de la privacidad van contra nuestras directrices. Los autores no son responsables del mal uso de la aplicación.

---

## Requisitos y dependencias

Las versiones de escritorio usan **Flutter** (recomendado) o Sciter (obsoleto) para la interfaz.

### Dependencias C++ (vcpkg)

Necesitas [vcpkg](https://github.com/microsoft/vcpkg) con `VCPKG_ROOT` configurado:

- **Windows:**  
  `vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static`
- **Linux/macOS:**  
  `vcpkg install libvpx libyuv opus aom`

### Sciter (solo si compilas la UI legacy)

Para compilar con la interfaz Sciter (en desuso) debes descargar la biblioteca dinámica de Sciter:

- [Windows](https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.win/x64/sciter.dll)
- [Linux](https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so)
- [macOS](https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.osx/libsciter.dylib)

---

## Raw steps to build

1. Tener entorno de desarrollo Rust y compilador C++.
2. Instalar vcpkg y las dependencias anteriores.
3. Clonar el repositorio (con submódulos):
   ```sh
   git clone --recurse-submodules https://github.com/MarvaDesk/MarvaDesk
   cd MarvaDesk
   ```
4. Ejecutar:
   - **Con Flutter (recomendado):**  
     `python build.py --flutter`
   - **Solo Rust + Sciter:**  
     `cargo run` (requiere la librería Sciter en `target/debug/`)

### Comandos de build útiles

| Comando | Descripción |
|--------|-------------|
| `python build.py --flutter` | Build escritorio con UI Flutter |
| `python build.py --flutter --release` | Build en modo release |
| `python build.py --hwcodec` | Build con codec por hardware |
| `python build.py --vram` | Build con VRAM (solo Windows) |
| `cargo build --release` | Solo binario Rust en release |
| `cargo build --features hwcodec` | Rust con codec por hardware |

### Móvil (Flutter)

```sh
cd flutter
flutter build android   # APK Android
flutter build ios       # App iOS
flutter run             # Ejecutar en dispositivo/emulador
flutter test            # Tests
```

---

## How to Build on Linux

### Ubuntu 18 / Debian 10

```sh
sudo apt install -y zip g++ gcc git curl wget nasm yasm libgtk-3-dev clang libxcb-randr0-dev libxdo-dev \
        libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev libasound2-dev libpulse-dev cmake make \
        libclang-dev ninja-build libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpam0g-dev
```

### openSUSE Tumbleweed

```sh
sudo zypper install gcc-c++ git curl wget nasm yasm gcc gtk3-devel clang libxcb-devel libXfixes-devel cmake alsa-lib-devel gstreamer-devel gstreamer-plugins-base-devel xdotool-devel pam-devel
```

### Fedora 28 / CentOS 8

```sh
sudo yum -y install gcc-c++ git curl wget nasm yasm gcc gtk3-devel clang libxcb-devel libxdo-devel libXfixes-devel pulseaudio-libs-devel cmake alsa-lib-devel gstreamer1-devel gstreamer1-plugins-base-devel pam-devel
```

### Arch / Manjaro

```sh
sudo pacman -Syu --needed unzip git cmake gcc curl wget yasm nasm zip make pkg-config clang gtk3 xdotool libxcb libxfixes alsa-lib pipewire
```

### Instalar vcpkg (Linux)

```sh
git clone https://github.com/microsoft/vcpkg
cd vcpkg
git checkout 2023.04.15
cd ..
./vcpkg/bootstrap-vcpkg.sh
export VCPKG_ROOT=$HOME/vcpkg
./vcpkg/vcpkg install libvpx libyuv opus aom
```

### Fix libvpx (Fedora)

```sh
cd vcpkg/buildtrees/libvpx/src
cd *
./configure
sed -i 's/CFLAGS+=-I/CFLAGS+=-fPIC -I/g' Makefile
sed -i 's/CXXFLAGS+=-I/CXXFLAGS+=-fPIC -I/g' Makefile
make
cp libvpx.a $VCPKG_ROOT/installed/x64-linux/lib/
cd
```

### Compilar (Linux, con Flutter)

**Verificación rápida de requisitos:**
```sh
./scripts/check_linux_build_requirements.sh
```

**Guía detallada:** Consulta [docs/BUILD_LINUX.md](docs/BUILD_LINUX.md) para requisitos completos, dependencias por distribución y solución de problemas.

**Pasos resumidos:**
```sh
# 1. Instalar dependencias (Ubuntu/Debian)
sudo apt install -y zip g++ gcc git curl wget nasm yasm libgtk-3-dev clang \
    libxcb-randr0-dev libxdo-dev libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev \
    libasound2-dev libpulse-dev cmake make libclang-dev ninja-build libssl-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpam0g-dev

# 2. vcpkg
git clone https://github.com/microsoft/vcpkg && cd vcpkg && ./bootstrap-vcpkg.sh
export VCPKG_ROOT=$PWD/vcpkg  # o $HOME/vcpkg
$VCPKG_ROOT/vcpkg install libvpx libyuv opus aom

# 3. Bridge (primera vez)
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h

# 4. Build
cd MarvaDesk
git submodule update --init --recursive
python3 build.py --flutter --hwcodec --unix-file-copy-paste
```

El paquete `marvadesk-1.4.6.deb` (o `.rpm`/`.pkg.tar.zst` según la distro) quedará en la raíz del proyecto.

### Generar .rpm y .pkg (Arch) desde una sola distro (p. ej. Linux Mint)

En una distro basada en Debian/Ubuntu solo se genera `.deb`. Para obtener también **.rpm** y **.pkg.tar.zst** desde la misma máquina se usan **dos imágenes Docker** (una para Fedora, otra para Arch), cada una con todo el sistema y herramientas ya instaladas.

**Flujo:**

1. **Una sola vez** (o cuando cambies de versión de Flutter/vcpkg): el script **construye la imagen** (tarda ~20–40 min):
   - Al ejecutar `./scripts/build-packages.sh rpm` por primera vez → construye la imagen `marvadesk-builder-fedora`.
   - Al ejecutar `./scripts/build-packages.sh arch` por primera vez → construye la imagen `marvadesk-builder-arch`.
2. **Las siguientes veces**: la imagen ya existe, el script solo **arranca el contenedor y ejecuta el build** (solo tarda lo que tarde compilar MarvaDesk).

**Comandos:**

```sh
# Instalar Docker una vez
sudo apt install docker.io
# Opcional: sudo usermod -aG docker $USER  (y cerrar sesión) para no usar sudo

# Solo .deb (en tu máquina)
./scripts/build-packages.sh
# o:  ./scripts/build-packages.sh deb

# .rpm (1ª vez: construye imagen Fedora; luego: solo build)
./scripts/build-packages.sh rpm

# .pkg Arch (1ª vez: construye imagen Arch; luego: solo build)
./scripts/build-packages.sh arch

# Los tres
./scripts/build-packages.sh all
```

Las imágenes se guardan en Docker (`marvadesk-builder-fedora`, `marvadesk-builder-arch`). No hay un solo contenedor con “Arch y RPM”: son dos imágenes distintas (Fedora para .rpm, Arch para .pkg). Los paquetes generados aparecen en la raíz del proyecto.

**Empaquetar solo desde el bundle (sin compilar en el contenedor):**  
Si ya compilaste (`python3 build.py --flutter`) y tienes el bundle en `flutter/build/linux/x64/release/bundle/`:

```sh
./scripts/build-packages.sh rpm-from-bundle   # .rpm desde el bundle (imagen mínima ~1 min)
./scripts/build-packages.sh arch-from-bundle  # .pkg desde el bundle (imagen mínima ~2-5 min)
```

**Convertir .deb → .rpm en tu máquina:** con `alien` (conversión aproximada):

```sh
sudo apt install alien
sudo alien -r marvadesk-1.4.6.deb
```

No hay herramienta estándar para .deb → .pkg (Arch); usa `arch-from-bundle` con el mismo bundle.

---

## How to build with Docker

Clona el repositorio y construye la imagen:

```sh
git clone https://github.com/MarvaDesk/MarvaDesk
cd MarvaDesk
git submodule update --init --recursive
docker build -t marvadesk-builder .
```

Para compilar cada vez:

```sh
docker run --rm -it -v $PWD:/home/user/marvadesk -v marvadesk-git-cache:/home/user/.cargo/git -v marvadesk-registry-cache:/home/user/.cargo/registry -e PUID="$(id -u)" -e PGID="$(id -g)" marvadesk-builder
```

Puedes añadir argumentos al final (por ejemplo `--release`). El ejecutable quedará en `target/debug/` o `target/release/` en tu máquina. Ejecuta desde la raíz del repositorio para que la aplicación encuentre los recursos.

```sh
# Debug
target/debug/rustdesk

# Release
target/release/rustdesk
```

*(Nota: el nombre del binario puede seguir siendo `rustdesk` por herencia del proyecto base; el producto es MarvaDesk.)*

---

## File Structure

| Ruta | Descripción |
|------|-------------|
| **libs/hbb_common** | Codec de vídeo, config, wrapper TCP/UDP, protobuf, funciones de transferencia de archivos y utilidades |
| **libs/scrap** | Captura de pantalla |
| **libs/enigo** | Control de teclado y ratón por plataforma |
| **libs/clipboard** | Implementación de copiar/pegar entre Windows, Linux y macOS |
| **src/ui** | UI legacy con Sciter (obsoleta) |
| **src/server** | Servicios de audio, portapapeles, entrada y vídeo; conexiones de red |
| **src/client.rs** | Inicio de la conexión entre pares |
| **src/rendezvous_mediator.rs** | Comunicación con el servidor de encuentro/relé |
| **src/platform** | Código específico por plataforma |
| **flutter** | Código Flutter para escritorio y móvil |
| **flutter/lib/desktop** | UI escritorio |
| **flutter/lib/mobile** | UI móvil |
| **flutter/lib/common** | Código compartido y modelos |

---

## Screenshots

Puedes añadir aquí capturas de pantalla de MarvaDesk (gestor de conexiones, escritorio remoto, transferencia de archivos, etc.).

---

## Testing

- **Rust:** `cargo test`
- **Flutter:** `cd flutter && flutter test`

---

## Contributing

Las contribuciones son bienvenidas. Consulta [CONTRIBUTING.md](docs/CONTRIBUTING.md) para empezar.

---

## Licencia

Consulta el archivo [LICENSE](LICENSE) de este repositorio.
