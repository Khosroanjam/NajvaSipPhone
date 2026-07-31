# MicroSIP — Agent Guide

## Build

- **IDE**: Visual Studio 2015 (v140 toolset). Open `microsip.vcxproj` in VS or build with MSBuild.
- **Configurations**: Debug|Win32, Debug|x64, Release|Win32, Release|x64.
- **Dependencies**: Prebuilt pjsip libraries expected at `..\pjlib\`, `..\pjsip\`, `..\pjmedia\`, `..\pjnath\`, `..\pjlib-util\` and third-party libs at `..\third_party\`. WebView2 via NuGet (`packages.config`).
- **Static MFC** (`UseOfMfc>Static</UseOfMfc>`), Unicode charset.
- **No lint, typecheck, or test infrastructure** in this repo. No CI config.
- **Precompiled header**: `stdafx.h` — must be included first in every .cpp.

## Architecture

- **Entrypoint**: `microsip.cpp` → `CmicrosipApp::InitInstance()` → creates `CmainDlg` (mainDlg.cpp).
- **SIP stack**: pjsua-lib (`pjsua.h`), linked statically via `#pragma comment(lib, "libpjproject-*")` in `mainDlg.h`.
- **Localization**: Custom `Translate()` macro wrapping `LangPackTranslateString` (`lib/langpack.cpp`). Language packs are loaded at runtime.
- **Settings**: INI-file based (`AccountSettings` in `settings.h`). Stored in `%APPDATA%\MicroSIP\`.
- **JSON**: Bundled jsoncpp in `lib\jsoncpp\`.
- **Addons**: `addons.cpp` / `addons.h` — thin hook that includes `mainDlg.h` (custom build-time feature, not a plugin system).
- **Crash handling**: `ExceptionFilter` in `microsip.cpp` writes `.txt` and `.dmp` crash dumps to the local app data directory.

## Key source layout

| Directory         | Contents |
|-------------------|----------|
| `.` (root)        | Dialog classes, controls, SIP wrappers |
| `lib/`            | Utilities: jsoncpp, Crypto, CSV, HID, langpack, Markup (XML), MSIP (pjsip wrapper) |
| `res/`            | Icons, bitmaps, RC2 fragments for dialog/menu resources |

All dialogs derive from `CBaseDialog`. Custom controls: `ButtonDialer`, `ButtonEx`, `ButtonBottom`, `ButtonSafe`, `IconButton`, `LevelsSliderCtrl`, `ClosableTabCtrl`, `StatusBar`.

## Key defines (`const.h` / `define.h`)

| Define | Purpose |
|--------|---------|
| `_GLOBAL_VIDEO` | Enables video feature set |
| `_GLOBAL_DTLS` | Enables DTLS support |
| `_GLOBAL_VERSION` | "3.22.3" |
| `_GLOBAL_KEY` | License key placeholder |
| `_GLOBAL_NAME` | "MicroSIP" |

## CLI arguments

- `/reset` — delete user data and settings
- `/resetnoask` — same, no confirmation prompt
- `/exit` — close running instance
- `/minimized` — launch minimized to tray
- `/answer` / `/hangupall` — remote-control commands for running instance

## Noteworthy

- Uses custom window message enum (`UM_*` in `global.h:28-86`) for inter-thread communication with the UI via `PostMessage`.
- Single-instance enforcement: `EnumWindows` + class name matching in `InitInstance`.
- HID (Human Interface Device) support via `lib/Hid.cpp` + `lib/hidapi.h`.
- Windows JumpList support (Windows 7+) in `jumplist.cpp`.
- Custom sortable list controls: `CListCtrl_Sortable` and `CListCtrl_SortItemsEx`.
