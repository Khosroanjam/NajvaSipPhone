#include "Logger.h"
#include <QDateTime>
#include <QDir>
#include <QDebug>
#include <pjsua2.hpp>

static Logger *s_instance = nullptr;

Logger *Logger::instance()
{
    if (!s_instance)
        s_instance = new Logger();
    return s_instance;
}

Logger::Logger(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
{
}

Logger::~Logger()
{
    if (m_file.isOpen())
        m_file.close();
}

void Logger::init(const QString &logPath)
{
    if (m_initialized)
        return;

    m_file.setFileName(logPath);
    if (m_file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        m_stream.setDevice(&m_file);
    }

    qInstallMessageHandler(Logger::messageHandler);

    qDebug() << "══════════════════════════════════════";
    qDebug() << " SagharSIP log started:" << QDateTime::currentDateTime().toString(Qt::ISODate);
    qDebug() << "══════════════════════════════════════";

    m_initialized = true;
}

void Logger::log(const QString &category, const QString &message)
{
    QMutexLocker lock(&m_mutex);
    if (m_file.isOpen()) {
        m_stream << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz")
                 << " [" << category << "] " << message << "\n";
        m_stream.flush();
    }
}

void Logger::messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    if (!s_instance || !s_instance->m_initialized)
        return;

    QString category;
    switch (type) {
    case QtDebugMsg:    category = QStringLiteral("DEBUG"); break;
    case QtInfoMsg:     category = QStringLiteral("INFO");  break;
    case QtWarningMsg:  category = QStringLiteral("WARN");  break;
    case QtCriticalMsg: category = QStringLiteral("CRIT");  break;
    case QtFatalMsg:    category = QStringLiteral("FATAL"); break;
    }

    QString location;
    if (ctx.file) {
        location = QString("%1:%2").arg(ctx.file, QString::number(ctx.line));
    }

    s_instance->log(category, msg + (location.isEmpty() ? QString() : QString("  [%1]").arg(location)));

    // Also print to stderr for immediate feedback
    fprintf(stderr, "[%s] %s\n", qPrintable(category), qPrintable(msg));
}

void Logger::pjsipLogHandler(int level, const char *data, int len)
{
    Q_UNUSED(len);
    if (!s_instance)
        return;

    static const char *levelNames[] = { "FATAL", "ERROR", "WARN", "INFO", "DEBUG", "TRACE", "TRACE2" };
    const char *lvl = (level >= 0 && level <= 6) ? levelNames[level] : "PJSIP";

    // data may contain newlines — split and log each line
    QString msg = QString::fromUtf8(data).trimmed();
    QStringList lines = msg.split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        s_instance->log(QString("PJSIP"), QString("[%1] %2").arg(lvl, line.trimmed()));
    }
}
