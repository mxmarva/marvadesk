# Flutter Rust Bridge – Regenerar archivos generados (Windows)

Este documento describe cómo regenerar los archivos generados por `flutter_rust_bridge_codegen` en Windows para que el build de MarvaDesk (por ejemplo `python build.py --flutter --marvadesk-cliente`) no falle por módulo `bridge_generated` no encontrado o tipos desalineados.

---

## 1. Cómo el repo genera los archivos

- **Entrada:** `src/flutter_ffi.rs` (API Rust expuesta a Flutter).
- **Herramienta:** `flutter_rust_bridge_codegen` **versión 1.80.1** con feature `uuid`.
- **Scripts de referencia:**
  - **flutter/run.sh:** instala codegen y ejecuta con `--rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./macos/Runner/bridge_generated.h` (desde carpeta `flutter/`).
  - **.github/workflows/bridge.yml:** mismo comando desde la **raíz del repo**, con rutas `./src/...` y `./flutter/...`; después copia el `.h` a `flutter/ios/Runner/`.
  - **build.py:** solo usa `--rust-input` y `--dart-output` (sin `--c-output`) en un script Linux embebido; no se usa para generar en Windows.

El codegen, al recibir `--rust-input ./src/flutter_ffi.rs`, genera por defecto los **Rust** en el mismo directorio que el input (`src/`), es decir:
- `src/bridge_generated.rs`
- `src/bridge_generated.io.rs`  
sin necesidad de pasar `--rust-output` (el CI no lo usa y sube esos archivos como artefactos).

---

## 2. Instalación del codegen (si hace falta)

Desde la **raíz del repositorio** (donde está `Cargo.toml` y la carpeta `src/`):

```powershell
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
```

Comprobar que está en el PATH:

```powershell
flutter_rust_bridge_codegen --version
```

Debe indicar **1.80.1**. Si no está en PATH, usar la ruta completa:

```powershell
$env:USERPROFILE\.cargo\bin\flutter_rust_bridge_codegen.exe --version
```

---

## 3. Comandos exactos en Windows (desde la raíz del repo)

Abre PowerShell o CMD y sitúate en la **raíz del repo** (por ejemplo `C:\Users\Marva\Documents\GitHub\MarvaDesk`).

### Paso 1 – Flutter pub get

```powershell
cd flutter
flutter pub get
cd ..
```

### Paso 2 – Generar bridge (Dart, C header y Rust)

Desde la **raíz del repo**:

```powershell
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
```

Si el ejecutable no está en PATH:

```powershell
& "$env:USERPROFILE\.cargo\bin\flutter_rust_bridge_codegen.exe" --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
```

### Paso 3 – Copiar el header a iOS

El proyecto espera el mismo `bridge_generated.h` en macOS e iOS. En PowerShell:

```powershell
Copy-Item -Path "flutter\macos\Runner\bridge_generated.h" -Destination "flutter\ios\Runner\bridge_generated.h" -Force
```

En CMD:

```cmd
copy /Y flutter\macos\Runner\bridge_generated.h flutter\ios\Runner\bridge_generated.h
```

---

## 4. Archivos esperados después de generar

Comprueba que existan:

| Archivo | Ubicación |
|---------|-----------|
| `bridge_generated.rs` | `src/bridge_generated.rs` |
| `bridge_generated.io.rs` | `src/bridge_generated.io.rs` |
| `generated_bridge.dart` | `flutter/lib/generated_bridge.dart` |
| `generated_bridge.freezed.dart` | `flutter/lib/generated_bridge.freezed.dart` (puede generarse junto al anterior) |
| `bridge_generated.h` | `flutter/macos/Runner/bridge_generated.h` |
| `bridge_generated.h` | `flutter/ios/Runner/bridge_generated.h` (copia del anterior) |

En PowerShell, comprobación rápida:

```powershell
Test-Path src/bridge_generated.rs; Test-Path src/bridge_generated.io.rs; Test-Path flutter/lib/generated_bridge.dart; Test-Path flutter/macos/Runner/bridge_generated.h; Test-Path flutter/ios/Runner/bridge_generated.h
```

Todos deben devolver `True`.

---

## 5. Si el codegen no genera los `.rs` en `src/`

Si tras el paso 2 **no** aparecen `src/bridge_generated.rs` y `src/bridge_generated.io.rs`, prueba a indicar la salida Rust de forma explícita. Desde la raíz del repo:

```powershell
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --rust-output ./src/bridge_generated.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
```

Algunas versiones generan un solo archivo Rust o el segundo con sufijo; si solo aparece `bridge_generated.rs`, revisa el `--help` de tu versión:

```powershell
flutter_rust_bridge_codegen --help
```

y busca `--rust-output` y la convención de nombres para el segundo archivo (p. ej. `.io.rs`).

---

## 6. Validación antes de volver a build

1. **Rust:** desde la raíz del repo:
   ```powershell
   cargo check --features "flutter,marvadesk_cliente"
   ```
   No debe haber errores de “file not found for module `bridge_generated`” ni de `EventToUI` / `IntoIntoDart`.

2. **Flutter:** desde `flutter/`:
   ```powershell
   cd flutter
   flutter pub get
   flutter analyze lib/generated_bridge.dart
   cd ..
   ```

3. **Build completo MarvaDesk (Windows):**
   ```powershell
   python build.py --flutter --marvadesk-cliente
   ```

Si todo pasa, los archivos generados están alineados con `src/flutter_ffi.rs` y el build puede seguir (incluido empaquetado e instalador).

---

## 7. Resumen rápido (copiar/pegar en PowerShell desde la raíz del repo)

```powershell
# Desde la raíz del repo (ej. C:\Users\Marva\Documents\GitHub\MarvaDesk)

# 1) Instalar codegen (solo la primera vez o si falta)
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid

# 2) Flutter deps
cd flutter; flutter pub get; cd ..

# 3) Generar bridge
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h

# 4) Copiar header a iOS
Copy-Item -Path "flutter\macos\Runner\bridge_generated.h" -Destination "flutter\ios\Runner\bridge_generated.h" -Force

# 5) Comprobar archivos
Test-Path src/bridge_generated.rs; Test-Path src/bridge_generated.io.rs; Test-Path flutter/lib/generated_bridge.dart

# 6) Validar Rust
cargo check --features "flutter,marvadesk_cliente"

# 7) Build MarvaDesk
python build.py --flutter --marvadesk-cliente
```

---

**Nota:** No se modifica lógica de negocio ni branding; solo se (re)generan los archivos del bridge a partir de `src/flutter_ffi.rs` y se alinean rutas/headers para Windows.
