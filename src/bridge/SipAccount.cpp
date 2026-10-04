#include "SipAccount.h"
#include <QDebug>
#include <QSettings>
#include <pjsua2.hpp>

SipAccount::SipAccount(QObject *parent)
    : QObject(parent)
    , m_isRegistered(false)
    , m_transport("UDP")
{
    loadConfig();
}

SipAccount::~SipAccount()
{
    try {
        shutdown();
    } catch (const pj::Error &) {
    }
}

bool SipAccount::isRegistered() const { return m_isRegistered; }
QString SipAccount::username() const { return m_username; }
QString SipAccount::password() const { return m_password; }
QString SipAccount::server() const { return m_server; }
QString SipAccount::proxy() const { return m_proxy; }
QString SipAccount::transport() const { return m_transport; }
QString SipAccount::displayName() const { return m_displayName; }

void SipAccount::setUsername(const QString &value)
{
    if (m_username != value) {
        m_username = value;
        emit usernameChanged();
    }
}

void SipAccount::setPassword(const QString &value)
{
    if (m_password != value) {
        m_password = value;
        emit passwordChanged();
    }
}

void SipAccount::setServer(const QString &value)
{
    if (m_server != value) {
        m_server = value;
        emit serverChanged();
    }
}

void SipAccount::setProxy(const QString &value)
{
    if (m_proxy != value) {
        m_proxy = value;
        emit proxyChanged();
    }
}

void SipAccount::setTransport(const QString &value)
{
    if (m_transport != value) {
        m_transport = value;
        emit transportChanged();
    }
}

void SipAccount::setDisplayName(const QString &value)
{
    if (m_displayName != value) {
        m_displayName = value;
        emit displayNameChanged();
    }
}

void SipAccount::setRegistered(bool registered)
{
    if (m_isRegistered != registered) {
        m_isRegistered = registered;
        emit registrationStateChanged();
    }
}

void SipAccount::login()
{
    if (m_username.isEmpty() || m_server.isEmpty()) {
        qWarning() << "[SipAccount] Cannot register: username or server missing";
        return;
    }

    try {
        if (getId() >= 0) {
            qDebug() << "[SipAccount] Already registered, re-registering...";
            setRegistration(true);
            return;
        }

        QString idUriStr = QString("sip:%1@%2").arg(m_username, m_server);
        QString regUriStr = QString("sip:%1").arg(m_server);

        pj::AccountConfig cfg;
        cfg.idUri = idUriStr.toStdString();
        cfg.regConfig.registrarUri = regUriStr.toStdString();
        cfg.regConfig.timeoutSec = 300;

        if (!m_proxy.isEmpty()) {
            cfg.sipConfig.proxies.push_back(
                QString("sip:%1;lr").arg(m_proxy).toStdString());
        }

        if (!m_password.isEmpty()) {
            pj::AuthCredInfo cred("digest", "*",
                                  m_username.toStdString(), 0,
                                  m_password.toStdString());
            cfg.sipConfig.authCreds.push_back(cred);
        }

        if (!m_displayName.isEmpty()) {
            QString displayUri = QString("\"%1\" <sip:%2@%3>")
                .arg(m_displayName, m_username, m_server);
            cfg.idUri = displayUri.toStdString();
        }

        create(cfg, true);
        qDebug() << "[SipAccount] Registering:" << idUriStr << "->" << regUriStr;
    } catch (const pj::Error &err) {
        qWarning() << "[SipAccount] Registration failed:" << err.info().c_str();
    }
}

void SipAccount::logout()
{
    try {
        if (getId() >= 0) {
            setRegistration(false);
            qDebug() << "[SipAccount] Unregistering...";
        }
    } catch (const pj::Error &err) {
        qWarning() << "[SipAccount] Logout failed:" << err.info().c_str();
    }
}

void SipAccount::saveConfig()
{
    QSettings settings("SagharSIP", "SagharSIP");
    settings.beginGroup("Account");
    settings.setValue("username", m_username);
    settings.setValue("password", m_password);
    settings.setValue("server", m_server);
    settings.setValue("proxy", m_proxy);
    settings.setValue("transport", m_transport);
    settings.setValue("displayName", m_displayName);
    settings.endGroup();
}

void SipAccount::onRegState(pj::OnRegStateParam &prm)
{
    PJ_UNUSED_ARG(prm);
    try {
        pj::AccountInfo ai = getInfo();

        QString statusText = QString::fromStdString(ai.regStatusText);
        int code = ai.regStatus;
        bool isActive = ai.regIsActive;

        // Only consider registered when server confirms with 200 OK
        bool actuallyRegistered = (isActive && code == PJSIP_SC_OK);

        qDebug() << "[SipAccount] onRegState:"
                 << "active=" << isActive
                 << "code=" << code << "(" << statusText << ")"
                 << "registered=" << actuallyRegistered;

        if (m_isRegistered != actuallyRegistered) {
            m_isRegistered = actuallyRegistered;
            emit registrationStateChanged();
        }
    } catch (const pj::Error &err) {
        qWarning() << "[SipAccount] onRegState error:" << err.info().c_str();
    }
}

// Split a remote party header (e.g. "\"Name\" <sip:101@host>") into user part
// and display name using the PJSIP URI parser.
static void parseRemoteParty(const pj_str_t &info, QString &number, QString &displayName)
{
    number = QString::fromUtf8(info.ptr, int(info.slen));
    displayName.clear();

    pj_pool_t *pool = pjsua_pool_create("remote-uri", 512, 512);
    if (!pool)
        return;

    pj_str_t buf;
    pj_strdup_with_null(pool, &buf, &info);
    pjsip_uri *uri = pjsip_parse_uri(pool, buf.ptr, buf.slen, PJSIP_PARSE_URI_AS_NAMEADDR);
    if (uri) {
        auto *nameAddr = reinterpret_cast<pjsip_name_addr *>(uri);
        displayName = QString::fromUtf8(nameAddr->display.ptr, int(nameAddr->display.slen));
        void *inner = pjsip_uri_get_uri(uri);
        if (PJSIP_URI_SCHEME_IS_SIP(inner) || PJSIP_URI_SCHEME_IS_SIPS(inner)) {
            auto *sipUri = static_cast<pjsip_sip_uri *>(inner);
            const pj_str_t &part = sipUri->user.slen > 0 ? sipUri->user : sipUri->host;
            number = QString::fromUtf8(part.ptr, int(part.slen));
        }
    }
    pj_pool_release(pool);
}

void SipAccount::onIncomingCall(pj::OnIncomingCallParam &prm)
{
    // Read caller info via the C API. Do NOT use a temporary pj::Call here:
    // ~pj::Call() hangs up the call it is attached to.
    pjsua_call_info ci;
    if (pjsua_call_get_info(prm.callId, &ci) != PJ_SUCCESS) {
        qWarning() << "[SipAccount] onIncomingCall: cannot read call info";
        return;
    }

    QString number, displayName;
    parseRemoteParty(ci.remote_info, number, displayName);
    qDebug() << "[SipAccount] Incoming call from:" << number << displayName;

    // The receiver must attach a pj::Call before this callback returns,
    // otherwise pjsua2 rejects the call with 500 (see Endpoint::on_incoming_call).
    emit incomingCall(prm.callId, number, displayName);
}

void SipAccount::loadConfig()
{
    QSettings settings("SagharSIP", "SagharSIP");
    settings.beginGroup("Account");
    m_username = settings.value("username").toString();
    m_password = settings.value("password").toString();
    m_server = settings.value("server").toString();
    m_proxy = settings.value("proxy").toString();
    m_transport = settings.value("transport", "UDP").toString();
    m_displayName = settings.value("displayName").toString();
    settings.endGroup();
}
