#ifndef SIPCALL_H
#define SIPCALL_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <pjsua2.hpp>

class SipCall : public QObject, public pj::Call
{
    Q_OBJECT
    Q_PROPERTY(int callId READ callId CONSTANT)
    Q_PROPERTY(QString remoteNumber READ remoteNumber CONSTANT)
    Q_PROPERTY(QString callState READ callState NOTIFY stateChanged)
    Q_PROPERTY(QString direction READ direction CONSTANT)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString callerName READ callerName NOTIFY callerNameChanged)
    Q_PROPERTY(bool muted READ isMuted WRITE setMuted NOTIFY mutedChanged)

public:
    SipCall(pj::Account &acc, int pjCallId, int ourCallId,
            QObject *parent = nullptr);
    ~SipCall();

    int callId() const;
    QString remoteNumber() const;
    QString callState() const;
    QString direction() const;
    int duration() const;
    QString callerName() const;
    bool isMuted() const;
    void setMuted(bool muted);

    Q_INVOKABLE void sendDtmf(const QString &digits);

    void makeCall(const std::string &dstUri, int ourId);
    void answer();
    void hangup();
    void setRemoteParty(const QString &number, const QString &displayName);

signals:
    void stateChanged();
    void disconnected();
    void durationChanged();
    void callerNameChanged();
    void mutedChanged();

protected:
    void onCallState(pj::OnCallStateParam &prm) override;
    void onCallMediaState(pj::OnCallMediaStateParam &prm) override;

private slots:
    void tickDuration();

private:
    void applyMicTransmit();

private:
    int m_callId;
    QString m_remoteNumber;
    QString m_callState;
    QString m_direction;
    QString m_callerName;
    bool m_isOutgoing;
    int m_duration;
    bool m_muted;
    QTimer m_durationTimer;
};

#endif // SIPCALL_H
