# SagharSIP — Agent Guide

## What this is

Fresh Qt 6.5.3 Widgets desktop app (CMake + Ninja + MinGW 64-bit), currently just a scaffold: `mainwindow.*` is an empty `QMainWindow`. `PROJECT_SPEC.md` exists but is empty.

## Build

- Kit: **Desktop Qt 6.5.3 MinGW 64-bit**. Qt at `C:\Qt\6.5.3\mingw_64`, MinGW 11.2.0 at `C:\Qt\Tools\mingw1120_64`, Ninja at `C:\Qt\Tools\Ninja`.
- Qt Creator build dir: `build\Desktop_Qt_6_5_3_MinGW_64_bit-Debug` (already configured). Output is `SagharSIP.exe`.
- Command-line build **requires MinGW on PATH** — without it AutoMoc fails with a cryptic "subprocess error":
  ```pwsh
  $env:PATH = "C:\Qt\Tools\mingw1120_64\bin;C:\Qt\6.5.3\mingw_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
  cmake --build build\Desktop_Qt_6_5_3_MinGW_64_bit-Debug
  ```
- Add new `.cpp/.h/.ui` files to the `qt_add_executable(...)` list in `CMakeLists.txt` (the generated `ui_mainwindow.h` is produced by CMake at build time — never edit generated files).

## `MicroSIP-3.22.3-src/` — vendored reference source

- Upstream MicroSIP 3.22.3 source tree. It is **not** part of the CMake build and does **not** compile with Qt/MinGW: it is a VS2015 (v140) MFC project needing prebuilt pjsip libs. Don't add its files to `CMakeLists.txt`.
- Treat it as reference for porting SIP features (SIP stack is pjsua-lib). It has its own guide at `MicroSIP-3.22.3-src\AGENTS.md`.

## Gotchas

- Not a git repo. No CI, tests, or lint setup.
- `CMakeLists.txt.user` is a Qt Creator per-user file — ignore it.
- Encoding is UTF-8 (Qt Creator codec).
