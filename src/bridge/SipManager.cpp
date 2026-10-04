#include "SipManager.h"
#include "SipAccount.h"
#include "SipCall.h"
#include "../Database.h"
#include "../network/ApiClient.h"

#include <pjsua2.hpp>
#include <exception>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>

SipManager::SipManager(QObject *parent)
    : QObject(parent)
    , m_account(nullptr)
    , m_callIdCounter(1)
    , m_initialized(false)
    , m_endpoint(new pj::Endpoint)
{
}

SipManager::~SipManager()
{
    shutdown();
}

bool SipManager::isRegistered() const
{
    return m_account ? m_account->isRegistered() : false;
}

int SipManager::activeCalls() const
{
    int count = 0;
    for (auto call : m_calls) {
        if (call->callState() != "DISCONNECTED")
            ++count;
    }
    return count;
}

SipAccount *SipManager::account() const
{
    return m_account;
}

pj::Endpoint &SipManager::endpoint()
{
    return *m_endpoint;
}

void SipManager::initialize()
{
    if (m_initialized)
        return;

        qDebug() << "[SipManager] Initializing PJSIP...";

        // Resolve hostname FIRST before pjsua_create(), because
        // pjsip_endpt_create() calls pj_gethostname() which does a
        // DNS lookup that can hang on systems with no DNS.
        pj_status_t status;
        status = pj_init();
        qDebug() << "[SipManager] pj_init:" << status;
        if (status != PJ_SUCCESS) {
            qWarning() << "[SipManager] pj_init failed:" << status;
            return;
        }

        const pj_str_t *hostname = pj_gethostname();
        qDebug() << "[SipManager] Hostname resolved:"
                 << QString::fromUtf8(hostname->ptr, (int)hostname->slen);

        status = pjlib_util_init();
        qDebug() << "[SipManager] pjlib_util_init:" << status;

        status = pjnath_init();
        qDebug() << "[SipManager] pjnath_init:" << status;

        // Now libCreate (pjsua_create) won't re-resolve hostname
        try {
            pj::EpConfig epConfig;
            epConfig.uaConfig.maxCalls = 4;
            epConfig.uaConfig.threadCnt = 0;
            epConfig.medConfig.clockRate = 8000;
            epConfig.medConfig.channelCount = 1;
            epConfig.medConfig.ecTailLen = 0;
            epConfig.medConfig.sndClockRate = 0;
            // Media uses its own ioqueue/thread for RTP, so SIP callbacks run
            // only from libHandleEvents() on the GUI thread (m_eventTimer).
            epConfig.medConfig.hasIoqueue = PJ_TRUE;

            // PJSIP internal log (SIP messages incl. SDP, media/RTP events)
            // written next to the exe; overwritten on each start.
            const QString pjLogPath = QDir(QCoreApplication::applicationDirPath())
                                          .filePath("pjsip.log");
            epConfig.logConfig.level = 5;
            epConfig.logConfig.consoleLevel = 0;
            epConfig.logConfig.msgLogging = PJ_TRUE;
            epConfig.logConfig.filename = QDir::toNativeSeparators(pjLogPath).toStdString();
            epConfig.logConfig.fileFlags = 0;
            qDebug() << "[SipManager] PJSIP log file:" << pjLogPath;

            qDebug() << "[SipManager] Calling libCreate...";
            m_endpoint->libCreate();

            qDebug() << "[SipManager] libInit...";
            m_endpoint->libInit(epConfig);

            qDebug() << "[SipManager] transportCreate...";
            pj::TransportConfig tcfg;
            tcfg.port = 0;
            m_endpoint->transportCreate(PJSIP_TRANSPORT_UDP, tcfg);

            qDebug() << "[SipManager] libStart...";
            m_endpoint->libStart();
            qDebug() << "[SipManager] PJSIP initialized successfully";

            // No PJSIP worker thread: poll timers (retransmissions,
            // re-registration) and events on the GUI thread.
            m_eventTimer.setInterval(10);
            connect(&m_eventTimer, &QTimer::timeout, this, [this]() {
                try {
                    m_endpoint->libHandleEvents(0);
                } catch (const pj::Error &err) {
                    qWarning() << "[SipManager] libHandleEvents:" << err.info().c_str();
                }
            });
            m_eventTimer.start();
        } catch (const pj::Error &err) {
            qWarning() << "[SipManager] PJSIP init failed (pj::Error):" << err.info().c_str();
            return;
        } catch (const std::exception &ex) {
            qWarning() << "[SipManager] PJSIP init failed (std::exception):" << ex.what();
            return;
        } catch (...) {
            qWarning() << "[SipManager] PJSIP init failed (unknown exception)";
            return;
        }

    m_account = new SipAccount(this);
    connect(m_account, &SipAccount::registrationStateChanged,
            this, &SipManager::registrationStateChanged);
    // Direct: the SipCall must exist before onIncomingCall() returns.
    connect(m_account, &SipAccount::incomingCall,
            this, &SipManager::handleIncomingCall, Qt::DirectConnection);

    m_initialized = true;

    if (!m_account->username().isEmpty() && !m_account->server().isEmpty()) {
        m_account->login();
    } else {
        qDebug() << "[SipManager] No SIP credentials — waiting for settings";
    }
}

void SipManager::shutdown()
{
    if (!m_initialized)
        return;

    qDebug() << "[SipManager] Shutting down...";

    qDeleteAll(m_calls);
    m_calls.clear();

    if (m_account) {
        m_account->logout();
    }

    m_eventTimer.stop();

    try {
        m_endpoint->libDestroy();
    } catch (const pj::Error &err) {
        qWarning() << "[SipManager] libDestroy failed:" << err.info().c_str();
    }

    m_initialized = false;
}

int SipManager::makeCall(const QString &number)
{
    if (!m_initialized || !m_account || number.isEmpty())
        return -1;

    try {
        QString uri;
        if (number.contains('@')) {
            uri = QString("sip:%1").arg(number);
        } else {
            uri = QString("sip:%1@%2").arg(number, m_account->server());
        }

        int callId = nextCallId();
        auto call = new SipCall(*m_account, PJSUA_INVALID_ID, callId, this);
        m_calls[callId] = call;

        connect(call, &SipCall::disconnected, this, &SipManager::onCallDisconnected);

        call->makeCall(uri.toStdString(), callId);
        qDebug() << "[SipManager] Outgoing call #" << callId << "to" << uri;
        emit callCreated(callId);
        emit activeCallsChanged();
        return callId;
    } catch (const pj::Error &err) {
        qWarning() << "[SipManager] makeCall failed:" << err.info().c_str();
        return -1;
    }
}

void SipManager::hangupCall(int callId)
{
    SipCall *call = findCall(callId);
    if (call) {
        try {
            call->hangup();
        } catch (const pj::Error &err) {
            qWarning() << "[SipManager] hangup failed:" << err.info().c_str();
        }
    }
}

void SipManager::answerCall(int callId)
{
    SipCall *call = findCall(callId);
    if (call) {
        try {
            call->answer();
        } catch (const pj::Error &err) {
            qWarning() << "[SipManager] answer failed:" << err.info().c_str();
        }
    }
}

SipCall *SipManager::findCall(int callId) const
{
    return m_calls.value(callId, nullptr);
}

void SipManager::reregister()
{
    if (!m_initialized || !m_account)
        return;
    m_account->logout();
    m_account->login();
}

void SipManager::handleIncomingCall(int callId, const QString &number, const QString &displayName)
{
    if (!m_initialized || !m_account)
        return;

    try {
        int ourCallId = nextCallId();
        auto call = new SipCall(*m_account, callId, ourCallId, this);
        call->setRemoteParty(number, displayName);
        m_calls[ourCallId] = call;

        connect(call, &SipCall::disconnected, this, &SipManager::onCallDisconnected);

        // Tell the caller we are alerting the user.
        pj::CallOpParam ringing;
        ringing.statusCode = PJSIP_SC_RINGING;
        call->pj::Call::answer(ringing);

        qDebug() << "[SipManager] Incoming call #" << ourCallId << "from" << number << displayName;
        emit incomingCall(ourCallId, number, displayName);
        emit activeCallsChanged();
    } catch (const pj::Error &err) {
        qWarning() << "[SipManager] handleIncomingCall failed:" << err.info().c_str();
    }
}

void SipManager::onAccountRegStateChanged()
{
    emit registrationStateChanged();
}

void SipManager::onCallDisconnected()
{
    auto call = qobject_cast<SipCall *>(sender());
    if (call) {
        qDebug() << "[SipManager] Call ended:" << call->callId()
                 << "duration:" << call->duration() << "s";
        int historyId = Database::instance()->addCallHistory(
            call->remoteNumber(), call->callerName(),
            call->direction(), call->duration());
        emit callEnded(call->callId());
        emit callHistoryCreated(call->callId(), historyId, call->remoteNumber(), call->callerName());

        // Sync to server
        if (ApiClient::instance()->isAuthenticated()) {
            ApiClient::instance()->createCallLog(
                call->remoteNumber(), call->callerName(),
                call->direction(), call->duration());
        }
    }
    emit activeCallsChanged();
}

int SipManager::nextCallId()
{
    return m_callIdCounter++;
}

QVariantList SipManager::captureDevices()
{
    QVariantList list;
    if (!m_initialized) return list;
    try {
        pj::AudDevManager &mgr = m_endpoint->audDevManager();
        unsigned count = mgr.getDevCount();
        for (unsigned i = 0; i < count; i++) {
            auto info = mgr.getDevInfo(i);
            if (info.inputCount > 0) {
                QVariantMap dev;
                dev["id"] = (int)i;
                dev["name"] = QString::fromStdString(info.name);
                dev["driver"] = QString::fromStdString(info.driver);
                list.append(dev);
            }
        }
    } catch (...) {}
    return list;
}

QVariantList SipManager::playbackDevices()
{
    QVariantList list;
    if (!m_initialized) return list;
    try {
        pj::AudDevManager &mgr = m_endpoint->audDevManager();
        unsigned count = mgr.getDevCount();
        for (unsigned i = 0; i < count; i++) {
            auto info = mgr.getDevInfo(i);
            if (info.outputCount > 0) {
                QVariantMap dev;
                dev["id"] = (int)i;
                dev["name"] = QString::fromStdString(info.name);
                dev["driver"] = QString::fromStdString(info.driver);
                list.append(dev);
            }
        }
    } catch (...) {}
    return list;
}

int SipManager::currentCaptureDevice()
{
    if (!m_initialized) return -1;
    try {
        return m_endpoint->audDevManager().getCaptureDev();
    } catch (...) { return -1; }
}

int SipManager::currentPlaybackDevice()
{
    if (!m_initialized) return -1;
    try {
        return m_endpoint->audDevManager().getPlaybackDev();
    } catch (...) { return -1; }
}

void SipManager::setCaptureDevice(int id)
{
    if (!m_initialized || id < 0) return;
    try {
        m_endpoint->audDevManager().setCaptureDev(id);
        qDebug() << "[SipManager] Capture device set to:" << id;
    } catch (const pj::Error &err) {
        qWarning() << "[SipManager] setCaptureDev failed:" << err.info().c_str();
    }
}

void SipManager::setPlaybackDevice(int id)
{
    if (!m_initialized || id < 0) return;
    try {
        m_endpoint->audDevManager().setPlaybackDev(id);
        qDebug() << "[SipManager] Playback device set to:" << id;
    } catch (const pj::Error &err) {
        qWarning() << "[SipManager] setPlaybackDev failed:" << err.info().c_str();
    }
}
