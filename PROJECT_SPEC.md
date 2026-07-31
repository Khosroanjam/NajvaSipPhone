# Project Specification: Modern Qt6/QML SIP Softphone

## 1. Project Objective
Develop a modern, lightweight, and cross-platform (Windows-first) SIP Softphone application. The application must separate the SIP protocol logic from the User Interface using a strict 3-layer architecture. The UI must be built with Qt6/QML for a modern, animated, and responsive experience, while the backend must rely on the robust `pjsua2` (C++ API of PJSIP) library.

## 2. Technology Stack
- **Frontend:** Qt 6.x, QML, Qt Quick Controls 2, Qt Multimedia (for audio device management).
- **Backend/Core:** C++17 or C++20, PJSIP (specifically `pjsua2` C++ Object-Oriented API).
- **Build System:** CMake (Minimum version 3.16).
- **Compiler:** MSVC 2022 (x64) or MinGW64 (Ensure consistency between Qt and PJSIP builds).
- **Architecture:** MVVM-like (Model: PJSUA2, ViewModel: QObject Wrappers, View: QML).

---

## 3. Legacy Analysis & Anti-Patterns (Based on MicroSIP Source Code)
*You must strictly AVOID the following patterns found in legacy MicroSIP code and use the Modern Qt/PJSUA2 alternatives:*

| Legacy Anti-Pattern (MicroSIP) | Modern Alternative (Required) | Reason |
| :--- | :--- | :--- |
| Manual string parsing for SIP URIs (e.g., searching for `@`, `;`). | Use `pj::NameAddr` and `pj::SipUri` from `pjsua2`. | Prevents parsing bugs with complex URIs, IPv6, or multiple parameters. |
| Using `malloc`/`free` for string conversion (e.g., `StrToPjStr`). | Use `QString::toStdString()` and `pj::str_t(std_string)`. | Prevents memory leaks. Rely on RAII and modern C++ string management. |
| Using `PostMessage` and `WM_USER` for cross-thread communication. | Use Qt `signals` and `slots` (with `Qt::QueuedConnection`). | Guarantees thread safety between PJSIP worker threads and the Qt Main GUI thread. |
| Hardcoded error messages (e.g., `if (status == 171039)`). | Use `pj::Endpoint::utilStrError(status)` + `tr()` for localization. | Cleaner, maintainable, and supports Qt Linguist for multi-language. |
| Direct MFC `CString` dependency throughout the logic. | Use `QString` for UI/Logic and `std::string` for PJSUA2 boundary. | Decouples logic from Windows-specific frameworks. |
| Manual audio level looping (`pjsua_conf_adjust_rx_level`). | Use `pj::AudDevManager` or manage `pj::ConfPort` levels properly. | More efficient and aligned with PJSUA2 design. |

---

## 4. System Architecture (3-Layer Model)

### Layer 1: Core (PJSUA2)
- The raw `pjsua2` library.
- Responsible for: SIP registration, NAT traversal (STUN/TURN), codec negotiation (Opus, PCMU, PCMA), and media handling.

### Layer 2: Bridge (C++ / Qt Wrapper)
- Classes inheriting from `QObject` and `pj::Account` / `pj::Call`.
- **`SipManager` (Singleton or top-level QObject):** Initializes `pj::Endpoint`, manages global audio devices, and acts as a factory for Accounts/Calls.
- **`SipAccount`:** Wraps `pj::Account`. Emits `registrationStateChanged(bool)`.
- **`SipCall`:** Wraps `pj::Call`. Overrides `onCallState`, `onIncomingCall`. Emits `callStateChanged`, `incomingCall`.

### Layer 3: UI (QML)
- Pure presentation layer.
- Uses `Q_PROPERTY` to read state (e.g., `isRegistered`, `currentCallStatus`).
- Uses `Q_INVOKABLE` methods to trigger actions (e.g., `makeCall(number)`, `answerCall()`).
- **NO SIP logic or direct PJSIP includes** should exist in QML or UI-facing C++ code.

---

## 5. Step-by-Step Implementation Roadmap

Execute this roadmap sequentially. **Do not jump ahead.** Provide the code for each phase and wait for my validation before proceeding to the next.

### Phase 1: Build System & PJSIP Integration
1. Provide a robust `CMakeLists.txt` that finds Qt6 components (`Core`, `Quick`, `Multimedia`).
2. Provide instructions/CMake logic to link pre-compiled `pjsua2` libraries (include directories and library paths).
3. Create a minimal `main.cpp` that initializes the QML engine and registers the C++ types.

### Phase 2: Core C++ Bridge Implementation
1. Implement `SipManager.h/.cpp`: 
   - Initialize `pj::Endpoint`.
   - Configure basic audio settings (clock rate, channel count).
   - Provide `Q_INVOKABLE void init()` and `Q_INVOKABLE void shutdown()`.
2. Implement `SipAccount.h/.cpp`:
   - Inherit from `pj::Account` and `QObject`.
   - Implement `onRegState(pj::OnRegStateParam &prm)` override.
   - Emit a Qt signal `void registrationChanged(bool isRegistered, const QString &statusText)`.
3. Implement `SipCall.h/.cpp`:
   - Inherit from `pj::Call` and `QObject`.
   - Implement `onCallState(pj::OnCallStateParam &prm)` override.
   - Emit signals: `void stateChanged(const QString &state)`, `void disconnected()`.

### Phase 3: QML User Interface (Modern Design)
1. Create `Main.qml`: A sleek, borderless window (FramelessWindowHint) with a sidebar for navigation (Dialer, Settings, Status).
2. Create `Dialpad.qml`: A modern numeric keypad with a display field, using Qt Quick Controls 2. Include a "Call" (Green) and "Hangup" (Red) button.
3. Create `CallScreen.qml`: An overlay or separate view showing caller ID, call duration (timer), and Answer/Hangup buttons.
4. Ensure all UI components are responsive and support a basic Dark/Light theme.

### Phase 4: Integration & Data Binding
1. Connect the `Dialpad.qml` "Call" button to `sipManager.makeCall(number)`.
2. Connect the `SipCall::incomingCall` signal to open the `CallScreen.qml` dialog.
3. Implement a `CallTimer` in QML that starts when the call state becomes "CONNECTED".

### Phase 5: Audio & Polish
1. Use `QMediaDevices` to populate a QML ComboBox for selecting Input/Output audio devices.
2. Pass the selected device names to `SipManager` to set the active PJSIP audio devices.
3. Add basic error handling (e.g., showing a QML Snackbar/Toast when registration fails).

---

## 6. Strict Coding Rules for the Agent
1. **Thread Safety:** PJSIP callbacks (`onIncomingCall`, etc.) execute on a background thread. You **MUST** emit Qt signals from these callbacks. The connection to QML will automatically handle the thread jump via `Qt::QueuedConnection`. Never manipulate `QObject` UI properties directly inside a PJSIP callback.
2. **Memory Management:** Use `std::unique_ptr` for PJSIP objects where applicable, or rely on Qt's parent-child object tree. Avoid raw `new`/`delete`.
3. **String Encoding:** Always assume SIP data is UTF-8. Convert `pj::str_t` to `std::string`, then to `QString` using `QString::fromStdString()`.
4. **Error Handling:** Wrap all PJSUA2 calls in `try { ... } catch (const pj::Error& e) { qWarning() << e.info(); }` blocks to prevent application crashes.

---

## 7. Expected Output Format
For each phase, provide:
1. A brief explanation of the files being created.
2. The complete, compilable code for the C++ headers, source files, and QML files.
3. The updated `CMakeLists.txt` if new files are added.
4. **Stop and ask for my confirmation** before moving to the next phase.

**Acknowledge this specification by stating: "Specification received. Ready to begin Phase 1: Build System & PJSIP Integration. Please confirm."**