cmake_minimum_required(VERSION 3.19)
project(SagharSIP LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Qt6 ──────────────────────────────────────────────────────────────
find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick Sql Network)
find_package(Qt6 6.5 QUIET COMPONENTS Multimedia)
if(Qt6Multimedia_FOUND)
    set(HAS_QT_MULTIMEDIA TRUE)
else()
    set(HAS_QT_MULTIMEDIA FALSE)
    message(NOTICE "Qt6Multimedia not found — audio device selection will be disabled.")
endif()

qt_standard_project_setup()

# ── PJSIP config (libraries linked after target is created) ──────────
set(PJSIP_ROOT "" CACHE PATH "PJSIP installation root directory")
set(PJSIP_INCLUDE_DIR "${PJSIP_ROOT}/include" CACHE PATH "PJSIP include directory")
set(PJSIP_LIB_DIR "${PJSIP_ROOT}/lib" CACHE PATH "PJSIP library directory (Win64)")

set(PJSIP_LIBS
    pjsua2
    pjsua-lib
    pjsip-ua
    pjsip-simple
    pjsip-core
    pjmedia-codec
    pjmedia-audiodev
    pjmedia
    pjnath
    pjlib-util
    pjlib
    # third-party codec / utility libs
    libgsmcodec
    libilbccodec
    libspeex
    libsrtp
    libresample
)

# ── Sources ──────────────────────────────────────────────────────────
qt_add_executable(SagharSIP
    WIN32 MACOSX_BUNDLE
    main.cpp
    src/Logger.h src/Logger.cpp
    src/Database.h src/Database.cpp
    src/bridge/SipManager.h src/bridge/SipManager.cpp
    src/bridge/SipAccount.h src/bridge/SipAccount.cpp
    src/bridge/SipCall.h src/bridge/SipCall.cpp
    src/network/ApiClient.h src/network/ApiClient.cpp
    src/network/SyncEngine.h src/network/SyncEngine.cpp
    src/calendar/JalaliDate.h src/calendar/JalaliDate.cpp
    resources.qrc
)

# ── Qt Link ──────────────────────────────────────────────────────────
target_link_libraries(SagharSIP
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Sql
        Qt6::Network
)
if(HAS_QT_MULTIMEDIA)
    target_link_libraries(SagharSIP PRIVATE Qt6::Multimedia)
    target_compile_definitions(SagharSIP PRIVATE HAS_QT_MULTIMEDIA)
endif()

# ── PJSIP Link ───────────────────────────────────────────────────────
if(PJSIP_ROOT)
    if(WIN32)
        set(PJSIP_DEFINITIONS PJ_AUTOCONF=1 PJ_WIN32=1)
    endif()

    target_include_directories(SagharSIP PRIVATE ${PJSIP_INCLUDE_DIR})

    foreach(lib ${PJSIP_LIBS})
        find_library(PJSIP_${lib}_LIBRARY ${lib} PATHS ${PJSIP_LIB_DIR} NO_DEFAULT_PATH)
        if(PJSIP_${lib}_LIBRARY)
            target_link_libraries(SagharSIP PRIVATE ${PJSIP_${lib}_LIBRARY})
        else()
            message(WARNING "PJSIP library not found: ${lib} (looked in ${PJSIP_LIB_DIR})")
        endif()
    endforeach()

    if(WIN32)
        target_link_libraries(SagharSIP PRIVATE ws2_32 ole32 winmm)
        target_compile_definitions(SagharSIP PRIVATE ${PJSIP_DEFINITIONS})
    endif()
endif()

# ── Post-build: deploy Qt runtime dependencies ───────────────────────
find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS ${_qt6_install_prefix}/bin)
if(WINDEPLOYQT_EXECUTABLE)
    add_custom_command(TARGET SagharSIP POST_BUILD
        COMMAND ${WINDEPLOYQT_EXECUTABLE}
            --qmldir "${CMAKE_SOURCE_DIR}/qml"
            "$<TARGET_FILE:SagharSIP>"
        COMMENT "Deploying Qt runtime dependencies..."
    )
endif()

# ── Install ──────────────────────────────────────────────────────────
include(GNUInstallDirs)

install(TARGETS SagharSIP
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_app_script(
    TARGET SagharSIP
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT ${deploy_script})
