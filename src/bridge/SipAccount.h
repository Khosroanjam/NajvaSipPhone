#ifndef SIPACCOUNT_H
#define SIPACCOUNT_H

#include <QObject>
#include <QString>
#include <pjsua2.hpp>

class SipAccount : public QObject, public pj::Account
{
    Q_OBJECT
    Q_PROPERTY(bool isRegistered READ isRegistered NOTIFY registrationStateChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QString server READ server WRITE setServer NOTIFY serverChanged)
    Q_PROPERTY(QString proxy READ proxy WRITE setProxy NOTIFY proxyChanged)
    Q_PROPERTY(QString transport READ transport WRITE setTransport NOTIFY transportChanged)
    Q_PROPERTY(QString displayName READ displayName WRITE setDisplayName NOTIFY displayNameChanged)

public:
    explicit SipAccount(QObject *parent = nullptr);
    ~SipAccount();

    bool isRegistered() const;
    QString username() const;
    QString password() const;
    QString server() const;
    QString proxy() const;
    QString transport() const;
    QString displayName() const;

    Q_INVOKABLE void setUsername(const QString &value);
    Q_INVOKABLE void setPassword(const QString &value);
    Q_INVOKABLE void setServer(const QString &value);
    Q_INVOKABLE void setProxy(const QString &value);
    Q_INVOKABLE void setTransport(const QString &value);
    Q_INVOKABLE void setDisplayName(const QString &value);

    Q_INVOKABLE void login();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void saveConfig();

    void setRegistered(bool registered);

signals:
    void registrationStateChanged();
    void usernameChanged();
    void passwordChanged();
    void serverChanged();
    void proxyChanged();
    void transportChanged();
    void displayNameChanged();
    void incomingCall(int callId, const QString &number, const QString &displayName);

protected:
    void onRegState(pj::OnRegStateParam &prm) override;
    void onIncomingCall(pj::OnIncomingCallParam &prm) override;

private:
    void loadConfig();

    bool m_isRegistered;
    QString m_username;
    QString m_password;
    QString m_server;
    QString m_proxy;
    QString m_transport;
    QString m_displayName;
};

#endif // SIPACCOUNT_H
