<p align="center">
  <img src="icons/najva-256.png" width="128" height="128" alt="Najva icon">
</p>

# Najva

**Najva** is a modern desktop SIP softphone with a built-in call-center CRM, built with **Qt 6 / QML** on top of **PJSIP (pjsua2)**. It is Windows-first and designed for operators who spend the whole day on the phone: dial, answer, take notes after each call, look up callers in a phonebook, and review call activity on a Jalali (Persian) calendar.

> Internal project/target name: `SagharSIP`.

**Download:** prebuilt Windows x64 packages are on the [Releases](https://github.com/Khosroanjam/NajvaSipPhone/releases) page. Unzip the package and run `SagharSIP.exe`. If it does not start on a PC without Visual Studio, run the bundled `vc_redist.x64.exe` first.

---

## Features

**Phone**
- SIP registration (UDP) with PJSIP, live registration status in the UI
- Dialpad with keyboard input, paste support and Enter-to-call
- Incoming calls with Answer / Decline, `180 Ringing` sent to the caller
- In-call mute and DTMF keypad
- Caller name resolved from the phonebook (numbers are matched on their last 10 digits, so `0912…`, `+98912…` and dial-prefixed numbers are treated as the same)

**CRM**
- Recent calls with search, missed/incoming/outgoing indicators, call back and "save to contacts"
- Phonebook page with add / edit / delete
- After-call note dialog, and a notes panel for each call
- The last notes for a caller are shown during the call

**Calendar**
- Jalali month view with call markers
- Day view (calls and their notes), monthly report, and search across numbers, names and notes

**App**
- Dark and light themes (persisted), custom frameless title bar
- Organization name shown in the title bar (Settings → Organization)
- Audio device selection (microphone / speaker)
- Optional sync with a central CRM server (contacts, call logs, notes)

---

## Architecture

The app uses a strict three-layer, MVVM-style design:

```
PJSUA2 (PJSIP C++ API)   →   C++ bridge (QObject wrappers)   →   QML UI
       model                        view-model                      view
```

| Layer | Location | Responsibility |
|---|---|---|
| SIP core | PJSIP `pjsua2` | Registration, calls, codecs, media |
| Bridge | `src/bridge/` | `SipManager` (endpoint, calls, devices), `SipAccount` (`pj::Account`), `SipCall` (`pj::Call`) |
| Data & sync | `src/Database.*`, `src/network/` | Local SQLite store, REST client, periodic sync engine |
| Calendar | `src/calendar/JalaliDate.*` | Jalali ↔ Gregorian conversion for the UI |
| UI | `qml/` | Pages (`phone/`, `crm/`, `calendar/`, `SettingsPage.qml`), shared `components/`, `theme/Theme.qml` |

C++ objects are exposed to QML as context properties: `sipManager`, `db`, `apiClient`, `syncEngine` and `jalaliDate`.

**Threading:** PJSIP runs without its own SIP worker thread. A Qt timer on the GUI thread drives `libHandleEvents()`, so all SIP callbacks run on the GUI thread. Media (RTP) has its own ioqueue and thread.

---

## Requirements

| | Version |
|---|---|
| OS | Windows 10 / 11 (x64) |
| Qt | 6.5+ (developed with **Qt 6.8.1 MSVC 2022 64-bit**); modules: Core, Quick, Quick Controls 2, Sql, Network, Multimedia (optional) |
| Compiler | Visual Studio 2022 (MSVC x64) |
| Build tools | CMake ≥ 3.19, Ninja |
| SIP stack | [PJSIP / pjproject](https://github.com/pjsip/pjproject) 2.15+, built with the **same compiler and CRT** as the app |

---

## Building

### 1. Build PJSIP

Build pjproject with MSVC x64 and install it to a folder, for example `C:\pjproject\install`, that contains `include\` and `lib\`. The app links these libraries:

```
pjsua2  pjsua-lib  pjsip-ua  pjsip-simple  pjsip-core
pjmedia-codec  pjmedia-audiodev  pjmedia  pjnath  pjlib-util  pjlib
libgsmcodec  libilbccodec  libspeex  libsrtp  libresample
```

> The PJSIP CRT (`/MD` or `/MDd`) must match the app's build type.

### 2. Configure and build the app

From a **Visual Studio x64 Developer prompt** (vcvars64):

```bat
cmake -G Ninja -B build-msvc ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=C:/Qt/6.8.1/msvc2022_64 ^
  -DPJSIP_ROOT=C:/pjproject/install

cmake --build build-msvc
```

The output is `build-msvc\SagharSIP.exe`. A post-build step runs `windeployqt` automatically, so the build folder is runnable.

You can also open `CMakeLists.txt` in **Qt Creator**: choose the *Desktop Qt 6.8.1 MSVC2022 64bit* kit and add `PJSIP_ROOT` in the CMake configuration.

> If `PJSIP_ROOT` is empty, PJSIP is not linked and the app cannot place real calls.

### Adding files

- New C++ files: add them to `qt_add_executable(...)` in `CMakeLists.txt`.
- New QML files: add them to `resources.qrc`, otherwise they will not load.

---

## Packaging a release

Run every command from a **Developer PowerShell for VS 2022** (or after `vcvars64.bat`) in the project folder. Without that environment the compiler cannot find the standard headers (`Cannot open include file: 'type_traits'`).

**1. Set the version** in `main.cpp` (`app.setApplicationVersion("0.1.0")`).

**2. Build in Release mode:**

```powershell
cmake --build build-msvc
```

**3. Create a clean, self-contained folder with `windeployqt`.** Use `windeployqt` rather than `cmake --install`: the QML is loaded from `resources.qrc`, so the CMake deploy script does not find the QML imports and the folder would not run on another PC.

```powershell
New-Item -ItemType Directory dist\Najva-0.1.0 -Force
Copy-Item build-msvc\SagharSIP.exe dist\Najva-0.1.0\
C:\Qt\6.8.1\msvc2022_64\bin\windeployqt.exe --release --qmldir qml --compiler-runtime --no-translations dist\Najva-0.1.0\SagharSIP.exe
```

This copies the Qt DLLs, plugins, QML modules (Controls, Layouts, Shapes, QtCore) and `vc_redist.x64.exe`. PJSIP is linked statically, so it needs no DLLs.

**4. Test the folder** on a PC without Qt (or with Qt removed from `PATH`), then zip it:

```powershell
Compress-Archive -Path dist\Najva-0.1.0 -DestinationPath dist\Najva-0.1.0-win64.zip
```

**5. Tag and publish:**

```bash
git tag -a v0.1.0 -m "Najva 0.1.0"
git push origin v0.1.0
```

On GitHub, go to **Releases → Draft a new release**, pick the `v0.1.0` tag, write the release notes, attach `Najva-0.1.0-win64.zip`, and click **Publish release**.

> `dist/` is git-ignored, so release packages are never committed.

---

## Configuration

Everything is configured in the app under **Settings**:

- **SIP account:** username/extension, password, server/domain, optional outbound proxy, display name, transport
- **Central server (sync):** server URL and API key
- **Audio devices:** microphone and speaker
- **Organization:** name shown in the title bar
- **Appearance:** dark / light theme

| What | Where |
|---|---|
| Settings | Windows registry, `HKCU\Software\SagharSIP\SagharSIP` |
| Local database | `%APPDATA%\SagharSIP\SagharSIP\sagharsip.db` (SQLite) |
| App log | `SagharSIP.log`, next to the executable |
| PJSIP log | `pjsip.log`, next to the executable (overwritten on each start) |

---

## CRM sync server (optional)

The app can sync with a small **FastAPI + PostgreSQL** server (`/api/v1/...`: auth, contacts, call logs, calendar, sync), which is kept in a separate `server/` directory:

```bash
cd server
docker compose up --build      # API on :8000, Postgres on :5432
python seed.py                 # creates a default company/operator and prints the phone API key
```

Then enter the server URL (for example `http://<host>:8000`) and the API key in **Settings → Central server**.

---

## Troubleshooting

- **"Offline" / not registered:** check that the PBX is reachable (VPN), and check the server and credentials in Settings. `pjsip.log` contains every SIP message.
- **One-way audio:** each finished call writes RTP TX/RX statistics and the media addresses to `SagharSIP.log`. Check that the address advertised in the SDP is reachable from the PBX, and that the PBX NAT settings fit your network.
- **Codecs:** PCMU, PCMA, G.722, iLBC, Speex and GSM are available. Opus is not included, because the default PJSIP build has no external codec libraries.

---

## Repository notes

- `MicroSIP-3.22.3-src/` is vendored reference code (MFC) and is **not** part of the build.
- `mainwindow.*` is an unused Qt Widgets scaffold.
- `PROJECT_SPEC.md` is the design spec and `PROJECT_STATE.md` tracks progress.

---

## Author

**Sadegh Khosroanjam** · [@khosroanjam](https://github.com/Khosroanjam)
