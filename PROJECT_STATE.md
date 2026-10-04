# SagharSIP — Project State

## Overview
Modern Qt6/QML SIP Softphone (Windows-first), Phase 1-3 complete, real PJSIP integrated.

## Tech Stack
- **UI:** Qt 6.5.3, QML, Qt Quick Controls 2
- **Backend C++:** C++17
- **Build:** CMake 3.19+ + Ninja + MSVC 2022 (primary) / MinGW 11.2.0 (legacy mock)
- **Architecture:** MVVM (Model: PJSUA2 → Bridge: QObject+PJSIP wrappers → View: QML)
- **PJSIP:** pjproject 2.15+ built with MSVC (Debug-Dynamic, /MDd). Installed at `C:\pjproject\install\`
- **Qt Multimedia:** Found (msvc2019_64 kit) — audio device selection enabled.

## Directory Structure
```
SagharSIP/
├── CMakeLists.txt              # Qt6 Core+Quick+Multimedia + PJSIP (11 main + 5 third-party libs)
├── main.cpp                    # QGuiApplication + QQmlApplicationEngine, SipManager
├── resources.qrc               # All QML files embedded as qrc resources
├── qml/
│   ├── Main.qml                # Root ApplicationWindow, SplitView (PhonePanel + CrmPanel)
│   ├── SettingsPage.qml        # SIP account settings form
│   ├── phone/
│   │   ├── PhonePanel.qml      # Dialpad + CallScreen tabs
│   │   ├── Dialpad.qml         # Numeric keypad, call button
│   │   └── CallScreen.qml      # Active call UI (answer/hangup, duration)
│   ├── crm/
│   │   ├── CrmPanel.qml        # Contact list + call history panel
│   │   ├── ContactHeader.qml   # Contact detail header
│   │   ├── CallHistory.qml     # Call log list
│   │   └── NotesSection.qml   # Contact notes
│   └── theme/
│       ├── qmldir              # Singleton Theme declaration
│       └── Theme.qml           # Color palette, fonts, sizes
├── src/
│   ├── bridge/                 # Phase 2 ✓: real PJSIP integration
│   │   ├── SipManager.h/.cpp   # pj::Endpoint init, call management, QML context
│   │   ├── SipAccount.h/.cpp   # QObject + pj::Account: login/logout, onRegState
│   │   └── SipCall.h/.cpp      # QObject + pj::Call: make/answer/hangup, audio routing
│   └── core/                   # Empty — reserved for direct PJSUA2 usage
├── MicroSIP-3.22.3-src/        # Vendored reference (VS2015/MFC, not in build)
├── build/                      # MinGW build (legacy mock mode)
├── build-msvc/                 # MSVC build (active — real PJSIP)
├── mainwindow.h/cpp/ui         # Old Widgets scaffold (not compiled)
└── CMakeLists.txt.user         # Qt Creator per-user config
```

## Build Commands

**MSVC (primary — real PJSIP):**
```pwsh
# Requires Visual Studio 2022 and Qt 6.5.3 msvc2019_64
# Also needs PJSIP built at C:\pjproject\install\
cmd /c "call `"E:\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat`" && cmake --build build-msvc"
# Output: build-msvc\SagharSIP.exe
```

**MinGW (legacy — no PJSIP, mock only):**
```pwsh
$env:PATH = "C:\Qt\Tools\mingw1120_64\bin;C:\Qt\6.5.3\mingw_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
cmake --build build\Desktop_Qt_6_5_3_MinGW_64_bit-Debug
```

## CMakeLists.txt Key Points
- Requires Qt6 Core + Quick + Multimedia
- PJSIP via `-DPJSIP_ROOT=C:/pjproject/install` (15 libs total: pjsua2, pjsua-lib, pjsip-ua, pjsip-simple, pjsip-core, pjmedia-codec, pjmedia-audiodev, pjmedia, pjnath, pjlib-util, pjlib, libgsmcodec, libilbccodec, libspeex, libsrtp, libresample)
- Post-build `windeployqt --qmldir` deploys Qt runtime + QML plugins
- `PJ_AUTOCONF=1 PJ_WIN32=1` defines for PJSIP

## Phase Progress

| Phase | Status | Description |
|:---|:---|:---|
| 1 | Done | Build system, QML base, PJSIP CMake integration |
| 2 | Done | SipManager, SipAccount, SipCall — real PJSUA2 |
| 3 | Done | QML UI (Main, Dialpad, CallScreen, Settings, CRM) |
| 4 | Pending | Integration & end-to-end testing with Asterisk |
| 5 | Pending | Audio device selection UI, polish |

## Known Issues
1. No OPUS codec (PJSIP built without external codec libs). Supports PCMU, PCMA, G.722, iLBC, Speex, GSM built-in.
2. Build is Debug-only; Release build needs PJSIP Release-Dynamic libs.
3. No tests, lint, or CI. Verify by building and manual testing.
