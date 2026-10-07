#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QStandardPaths>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#include "src/Logger.h"
#include "src/Database.h"
#include "src/bridge/SipManager.h"
#include "src/bridge/SipCall.h"
#include "src/network/ApiClient.h"
#include "src/network/SyncEngine.h"
#include "src/calendar/JalaliDate.h"

int main(int argc, char *argv[])
{
#ifdef _WIN32
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("SagharSIP");
    app.setOrganizationName("SagharSIP");
    app.setApplicationVersion("0.1.3");
    app.setWindowIcon(QIcon(":/icons/najva.ico"));

    // Setup file logging
    QString logPath = QDir(QCoreApplication::applicationDirPath())
                          .filePath("SagharSIP.log");
    Logger::instance()->init(logPath);
    qDebug() << "Application started, log file:" << logPath;

    // Init on main thread — hostname is pre-resolved, so no DNS hang
    Database::instance()->init();
    SipManager sipManager;
    sipManager.initialize();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("sipManager", &sipManager);
    engine.rootContext()->setContextProperty("db", Database::instance());
    engine.rootContext()->setContextProperty("apiClient", ApiClient::instance());
    engine.rootContext()->setContextProperty("syncEngine", SyncEngine::instance());
    engine.rootContext()->setContextProperty("jalaliDate", new JalaliDate(&engine));

    // Auto-authenticate if server is configured
    if (ApiClient::instance()->isConfigured())
        ApiClient::instance()->authenticate();

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);

    int result = app.exec();
    qDebug() << "Application shutting down...";
    sipManager.shutdown();
    qDebug() << "Application exited.";
    return result;
}