#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QMutex>

class Logger : public QObject
{
    Q_OBJECT
public:
    static Logger *instance();

    void init(const QString &logPath);
    void log(const QString &category, const QString &message);
    static void pjsipLogHandler(int level, const char *data, int len);

private:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    static void messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg);

    QFile m_file;
    QTextStream m_stream;
    QMutex m_mutex;
    bool m_initialized;
};

#endif // LOGGER_H
