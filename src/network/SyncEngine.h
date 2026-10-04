#ifndef SYNCENGINE_H
#define SYNCENGINE_H

#include <QObject>
#include <QTimer>
#include <QJsonArray>

class ApiClient;

class SyncEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(int intervalSecs READ intervalSecs WRITE setIntervalSecs NOTIFY intervalSecsChanged)
    Q_PROPERTY(bool syncing READ isSyncing NOTIFY syncingChanged)

public:
    static SyncEngine *instance();

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    int intervalSecs() const { return m_intervalSecs; }
    void setIntervalSecs(int secs);

    bool isSyncing() const;

    Q_INVOKABLE void syncNow();

signals:
    void enabledChanged();
    void intervalSecsChanged();
    void syncingChanged();
    void syncStarted();
    void syncFinished(bool success);

private slots:
    void doSync();

private:
    explicit SyncEngine(QObject *parent = nullptr);

    ApiClient *m_api;
    QTimer *m_timer;
    bool m_enabled;
    bool m_syncing;
    int m_intervalSecs;
};

#endif // SYNCENGINE_H
