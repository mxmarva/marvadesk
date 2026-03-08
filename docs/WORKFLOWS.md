# Instrucciones para GitHub Actions Workflows (MarvaDesk)

Repositorio: **https://github.com/mxmarva/MarvaDesk**

---

## Cómo se ejecutan los Workflows

### 1. Automáticamente (sin hacer nada)

| Workflow | Cuándo se ejecuta |
|----------|--------------------|
| **Full Flutter CI** (`flutter-ci.yml`) | En cada **push** a la rama `master` y en cada **Pull Request**, salvo si solo cambias `docs/`, `README.md`, `.github/`, `res/`, `appimage/`, `flatpak/`. |
| **CI** (`ci.yml`) | Igual: **push** a `master` y **Pull Request** (mismas exclusiones de rutas). |
| **Flutter Nightly Build** (`flutter-nightly.yml`) | Todas las noches a las 00:00 UTC (cron). |
| **Flutter Tag Build** (`flutter-tag.yml`) | Cuando creas un **tag** de versión, por ejemplo: `1.4.6`, `v1.4.6`, `1.4.6-1`, `v1.4.6-1`. |
| **Fdroid** (`fdroid.yml`) | Al crear los mismos tags de versión; genera el archivo de versión para F-Droid. |
| **Publish to WinGet** (`winget.yml`) | Cuando **publicas un Release** en GitHub (no solo el tag). |

**Importante:** Si tu rama por defecto es **`main`** y no **`master`**, los workflows de CI/Flutter CI **no** se lanzarán en push. Tienes que o bien usar la rama `master`, o cambiar en los YAML la rama de `master` a `main`.

---

### 2. Manualmente (desde la web de GitHub)

1. Entra en tu repo: **https://github.com/mxmarva/MarvaDesk**
2. Pestaña **Actions**.
3. En el menú izquierdo elige el workflow que quieras.
4. Arriba a la derecha: botón **Run workflow**.
5. Elige la rama (por ejemplo `main` o `master`) y pulsa **Run workflow**.

Workflows que puedes lanzar a mano:

| Workflow | Uso típico |
|----------|------------|
| **Full Flutter CI** | Probar build completo (sin subir artefactos). |
| **CI** | Probar compilación Rust/legacy. |
| **Flutter Nightly Build** | Build completo y subir artefactos con tag `nightly`. |
| **Flutter Tag Build** | Solo con tag creado antes; si lo lanzas manual sin tag, el tag usado puede ser el de la rama. |
| **playground** | Build de prueba (playground). |
| **Publish to WinGet** | Publicar en WinGet (necesitas `WINGET_TOKEN` en Secrets). |
| **Fdroid version file generation** | Generar archivo de versión para F-Droid. |
| **Clear cache** | Borrar cachés de Actions si los builds fallan por caché corrupta. |

---

### 3. Resumen rápido por objetivo

- **Solo comprobar que el código compila**  
  Haz push a `master` (o abre un PR) y mira la pestaña **Actions**. O ejecuta manualmente **Full Flutter CI** o **CI**.

- **Generar instalables (nightly)**  
  Ejecuta manualmente **Flutter Nightly Build**. Los artefactos aparecen en la ejecución del workflow (Artifacts).

- **Generar instalables por versión**  
  Crea un tag (ej. `1.4.6` o `v1.4.6`) y empuja:  
  `git tag 1.4.6 && git push origin 1.4.6`  
  Se disparará **Flutter Tag Build** y podrás usar los artefactos o crear un Release.

- **Publicar en WinGet**  
  Crea un Release desde la pestaña **Releases** en GitHub. El workflow **Publish to WinGet** se ejecutará si está configurado `WINGET_TOKEN` en **Settings → Secrets and variables → Actions**.

- **Limpiar caché de Actions**  
  Actions → **Clear cache** → **Run workflow**.

---

## Secrets recomendados (Settings → Secrets and variables → Actions)

Para builds completos (firmado, etc.) hace falta configurar secrets; si no, algunos jobs pueden fallar o no subir artefactos:

- `ANDROID_SIGNING_KEY` – Android  
- `MACOS_P12_BASE64` – macOS  
- `WINGET_TOKEN` – solo si usas WinGet  
- `SIGN_BASE_URL` – si usas servidor de firma (flutter-build)

---

## Rama por defecto: `master` vs `main`

En los archivos `.github/workflows/ci.yml` y `.github/workflows/flutter-ci.yml` está configurada la rama **`master`**.  
Si en tu repo la rama por defecto es **`main`**, puedes:

- Cambiar en ambos YAML `branches: [master]` por `branches: [main]`, **o**
- Mantener una rama `master` actualizada con `main` y hacer push allí para disparar los workflows.

---

## Dónde ver los resultados y artefactos

- **Pestaña Actions:** lista de ejecuciones, logs y estado de cada job.
- **Artefactos:** en una ejecución concreta, al final de la página suele haber una sección **Artifacts** para descargar los instalables generados (cuando el workflow los sube).
