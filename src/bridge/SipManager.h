#ifndef SIPMANAGER_H
#define SIPMANAGER_H

#include <QObject>
#include <QMap>
#include <QTimer>
#include <QVariant>
#include <memory>

class SipAccount;
class SipCall;

namespace pj {
    class Endpoint;
}

class SipManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRegistered READ isRegistered NOTIFY registrationStateChanged)
    Q_PROPERTY(int activeCalls READ activeCalls NOTIFY activeCallsChanged)
    Q_PROPERTY(SipAccount* account READ account CONSTANT)
public:
    explicit SipManager(QObject *parent = nullptr);
    ~SipManager();

    bool isRegistered() const;
    int activeCalls() const;
    SipAccount *account() const;
    pj::Endpoint &endpoint();

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void reregister();
    Q_INVOKABLE int makeCall(const QString &number);
    Q_INVOKABLE void hangupCall(int callId);
    Q_INVOKABLE void answerCall(int callId);

    Q_INVOKABLE SipCall *findCall(int callId) const;

    // Audio device management
    Q_INVOKABLE QVariantList captureDevices();
    Q_INVOKABLE QVariantList playbackDevices();
    Q_INVOKABLE int currentCaptureDevice();
    Q_INVOKABLE int currentPlaybackDevice();
    Q_INVOKABLE void setCaptureDevice(int id);
    Q_INVOKABLE void setPlaybackDevice(int id);

signals:
    void registrationStateChanged();
    void activeCallsChanged();
    void incomingCall(int callId, const QString &callerNumber, const QString &callerName);
    void callCreated(int callId);
    void callEnded(int callId);
    void callFailed(const QString &reason);
    void callHistoryCreated(int callId, int callHistoryId, const QString &number, const QString &name);

private slots:
    void onAccountRegStateChanged();
    void onCallDisconnected();

private:
    void handleIncomingCall(int callId, const QString &number, const QString &displayName);
    int nextCallId();
    void ensureAudioDevices();

    SipAccount *m_account;
    QMap<int, SipCall *> m_calls;
    int m_callIdCounter;
    bool m_initialized;
    std::unique_ptr<pj::Endpoint> m_endpoint;
    QTimer m_eventTimer;   // drives PJSIP timers/events (threadCnt = 0)
};

#endif // SIPMANAGER_H
