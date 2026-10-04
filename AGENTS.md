# SagharSIP — Agent Guide

## What this is

Qt 6.5.3 QML/Quick SIP softphone (Windows-first), MVVM: PJSUA2 → C++ bridge (`src/bridge/`) → QML UI. `PROJECT_SPEC.md` is the authoritative spec; `PROJECT_STATE.md` tracks phase progress.

## Build (MSVC — working)

- Kit: **Qt 6.8.1 msvc2022_64** at `C:\Qt\6.8.1\msvc2022_64`, Visual Studio 2022 Enterprise (E:\).
- Requires PJSIP built at `C:\pjproject\install\` (source at `C:\pjproject\`).
- CLI build — vcvars must be active:
  ```pwsh
  cmd /c "call `"E:\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat`" && cmake --build build-msvc"
  ```
- Output is `build-msvc\SagharSIP.exe`. Post-build runs `windeployqt --qmldir` automatically.

## Build (MinGW — legacy, no PJSIP)

- Kit: **Desktop Qt 6.5.3 MinGW 64-bit**. Qt at `C:\Qt\6.5.3\mingw_64`, MinGW at `C:\Qt\Tools\mingw1120_64`.
  ```pwsh
  $env:PATH = "C:\Qt\Tools\mingw1120_64\bin;C:\Qt\6.5.3\mingw_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
  cmake --build build\Desktop_Qt_6_5_3_MinGW_64_bit-Debug
  ```
- MinGW build has **no PJSIP** (mock mode only). Use MSVC for real SIP.

## Adding files

- New `.cpp/.h` → add to `qt_add_executable(...)` in `CMakeLists.txt` (bridge classes live in `src/bridge/`).
- New `.qml` → add to `resources.qrc`, or it will **not** load.
- Theme is a singleton (`qml/theme/qmldir` → `singleton Theme`); QML imports it relatively: `import "theme"`.
- New PJSIP libs → add to `PJSIP_LIBS` in `CMakeLists.txt` and copy to `C:\pjproject\install\lib\`.
- Never edit generated files under `build-msvc/` or `build/`.

## Current state — real PJSIP (Phase 2 done)

- `SipManager` initializes `pj::Endpoint` (libCreate → libInit → UDP transport → libStart).
- `SipAccount` inherits `pj::Account` + `QObject`. `onRegState` emits `registrationStateChanged`.
- `SipCall` inherits `pj::Call` + `QObject`. `onCallState` emits `stateChanged`; `onCallMediaState` wires audio.
- PJSIP built with MSVC at `C:\pjproject\install\` (source: `C:\pjproject\`, Debug-Dynamic CRT /MDd).
- `Qt6Multimedia` is now found (msvc kit) → `HAS_QT_MULTIMEDIA` is on.
- Settings via `QSettings("SagharSIP", "SagharSIP")` → Windows registry.

## Layout / gotchas

- `mainwindow.*` are dead Widgets scaffold — not in build.
- `src/core/` is empty (reserved for direct PJSUA2 use).
- `MicroSIP-3.22.3-src/` is vendored reference (VS2015 MFC). **Not** part of the build.
- Git: one commit; `build/` and `.user` files are tracked (no `.gitignore`). No tests, lint, or CI.
- PJSIP build directory (`C:\pjproject\`) contains generated config headers from CMake configure step (needed for `os_auto.h`, `sip_autoconf.h`, etc.). Don't delete it.

## Workflow convention (from PROJECT_SPEC.md)

- Work phase-by-phase (Phases 1–5) **stop and ask for confirmation before moving to the next phase**.
- Mandatory: emit Qt signals from PJSIP callbacks (QueuedConnection crosses threads), wrap PJSUA2 calls in `try/catch (pj::Error)`, use `pj::NameAddr` for SIP URIs.
