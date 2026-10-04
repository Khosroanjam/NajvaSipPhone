# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

SagharSIP: a Windows-first Qt 6 / QML SIP softphone with a built-in CRM panel (contacts, call history, after-call notes, Jalali calendar). SIP is handled by PJSIP's `pjsua2` C++ API. The UI text is mostly Persian.

- `PROJECT_SPEC.md` is the authoritative spec: architecture, anti-patterns to avoid from MicroSIP, coding rules, and the phase roadmap.
- `PROJECT_STATE.md` tracks which phases are done.
- `PROJECT_UI_DESIGN.md` (in Persian) is the UI/theme spec for the QML panels.
- `AGENTS.md` is the existing agent guide. Keep it in sync with this file when build facts change.

Repository layout: this directory is its own git repo, and it is nested inside a parent repo at `..`. The parent repo also holds `../server/`, the FastAPI CRM backend that the client syncs with.

## Build

There are no tests, lint, or CI. To verify a change, build it and test it by hand.

**MSVC (primary, real PJSIP)**: Qt 6.8.1 `msvc2022_64` (`C:\Qt\6.8.1\msvc2022_64`), VS 2022 Enterprise on `E:\`. PJSIP is prebuilt at `C:\pjproject\install` and passed in with `-DPJSIP_ROOT`.

```pwsh
cmd /c "call `"E:\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat`" && cmake --build build-msvc"
```

- The output is `build-msvc\SagharSIP.exe`. A post-build step runs `windeployqt --qmldir qml` automatically.
- `build-msvc-release/` is a second configured tree. Both caches currently say `CMAKE_BUILD_TYPE=Release`, so check that the PJSIP libs' CRT (/MD vs /MDd) matches the build type before changing it.
- To configure a fresh tree: `cmake -G Ninja -B <dir> -DCMAKE_PREFIX_PATH=C:/Qt/6.8.1/msvc2022_64 -DPJSIP_ROOT=C:/pjproject/install -DCMAKE_BUILD_TYPE=Release`, run inside a vcvars shell.
- If `PJSIP_ROOT` is empty, the PJSIP link block is skipped. Missing libraries only produce CMake warnings, so look for link errors after a configure.
- `HAS_QT_MULTIMEDIA` is defined only when Qt6Multimedia is found. Audio-device code must stay behind `#ifdef HAS_QT_MULTIMEDIA`.

**MinGW (legacy)**: Qt 6.5.3 `mingw_64`, tree at `build/Desktop_Qt_6_5_3_MinGW_64_bit-Debug`. It is not linked against PJSIP, so it cannot make real SIP calls.

**Runtime log**: `SagharSIP.log` is written next to the exe (see `Logger`). It is the main debugging aid, and bridge code logs with `[SipManager]`-style prefixes.

## Architecture

The structure is MVVM in three layers. PJSUA2 is the model, QObject bridge classes are the view-model, and QML is the view. QML must never touch PJSIP directly.

`main.cpp` creates everything and exposes it to QML as **context properties**, not registered types:

| QML name | C++ | Role |
|---|---|---|
| `sipManager` | `src/bridge/SipManager` | Owns `pj::Endpoint`, the account, and the active call. Exposes `Q_INVOKABLE` call actions |
| `db` | `src/Database` (singleton) | Local SQLite store (`call_history`, `contacts`, `notes`) in `AppDataLocation` |
| `apiClient` | `src/network/ApiClient` (singleton) | REST client for `../server`. Exchanges an API key for a bearer token at `/api/v1/auth/token` |
| `syncEngine` | `src/network/SyncEngine` (singleton) | Timer-driven: pushes local DB rows to `POST /api/v1/sync` and merges the server's contacts back into `db` |
| `jalaliDate` | `src/calendar/JalaliDate` | Gregorian↔Jalali conversion for the calendar UI |

**PJSIP bridge rules** (from the spec, and mandatory):
- `SipAccount` inherits `pj::Account` + `QObject`, and `SipCall` inherits `pj::Call` + `QObject`.
- PJSIP callbacks (`onRegState`, `onCallState`, `onCallMediaState`, `onIncomingCall`) can run off the GUI thread. They must only emit signals or use `QMetaObject::invokeMethod(..., Qt::QueuedConnection)`. They must never mutate QML-facing state directly.
- Wrap every PJSUA2 call in `try { } catch (const pj::Error &e)`. Parse SIP URIs with `pj::NameAddr`/`pj::SipUri`, not by hand. Convert strings with `QString::fromStdString` and `toStdString` (UTF-8).
- `SipManager::initialize()` calls `pj_init()` and `pj_gethostname()` before `libCreate()` on purpose: it avoids a DNS hang inside `pjsip_endpt_create`. Keep that ordering.
- `EpConfig.uaConfig.threadCnt = 0` (no PJSIP worker thread). Nothing in `src/` calls `libHandleEvents`, so keep that in mind when you debug missing SIP or media events.

**Settings** are stored with `QSettings("SagharSIP", "SagharSIP")`, which on Windows means the registry. SIP account settings and the server URL and API key live there.

**QML**: the entry point is `qrc:/qml/Main.qml`, a `SplitView` with `phone/` (Dialpad, CallScreen, after-call notes) on one side and `crm/` and `calendar/` on the other. `qml/theme/Theme.qml` is a singleton declared in `qml/theme/qmldir` and imported relatively with `import "theme"`.

## Adding files

- New `.cpp`/`.h`: add it to `qt_add_executable(...)` in `CMakeLists.txt`. There is no globbing.
- New `.qml`: add it to `resources.qrc`, or it will not load at runtime.
- New PJSIP lib: add it to `PJSIP_LIBS` in `CMakeLists.txt`, and make sure it exists in `C:\pjproject\install\lib`.

## Not part of the build

- `mainwindow.*`: a dead Qt Widgets scaffold.
- `src/core/`: an empty, reserved directory.
- `MicroSIP-3.22.3-src/`: vendored MFC reference code. Read it for SIP behaviour, but don't copy its patterns (see the anti-pattern table in `PROJECT_SPEC.md`).
- `build/`, `build-msvc*/`: generated. Never edit them.
- `C:\pjproject\`: the PJSIP source tree. It holds generated config headers (`os_auto.h`, `sip_autoconf.h`) that the build needs, so don't delete it.

## CRM server (`../server`)

FastAPI + async SQLAlchemy + Postgres. Tables are created at startup with `create_all`, and there are no migrations yet even though Alembic is listed.

```bash
cd ../server && docker compose up --build
```

```bash
cd ../server && python seed.py
```

`seed.py` creates a default company and operator and prints the phone API key. The API listens on `:8000`, and `/health` is the liveness check. The routers in `app/routers/` (`auth`, `contacts`, `call_logs`, `calendar`, `sync`) mirror the methods on `ApiClient`.

## Workflow convention

`PROJECT_SPEC.md` requires working phase by phase (Phases 1–5). Stop and ask the user for confirmation before starting the next phase. Phases 1–3 are done, Phase 4 (end-to-end integration with Asterisk) is pending, and Phase 5 (audio device UI, polish) is pending.
