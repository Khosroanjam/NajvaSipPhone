#include "SipCall.h"
#include <QDebug>
#include <pjsua2.hpp>

SipCall::SipCall(pj::Account &acc, int pjCallId, int ourCallId,
                 QObject *parent)
    : QObject(parent)
    , pj::Call(acc, pjCallId)
    , m_callId(ourCallId)
    , m_callState(QStringLiteral("NULL"))
    , m_direction(pjCallId == PJSUA_INVALID_ID
                  ? QStringLiteral("outgoing") : QStringLiteral("incoming"))
    , m_isOutgoing(pjCallId == PJSUA_INVALID_ID)
    , m_duration(0)
    , m_muted(false)
{
    m_durationTimer.setInterval(1000);
    connect(&m_durationTimer, &QTimer::timeout, this, &SipCall::tickDuration);
}

SipCall::~SipCall()
{
    m_durationTimer.stop();
}

int SipCall::callId() const { return m_callId; }
QString SipCall::remoteNumber() const { return m_remoteNumber; }
QString SipCall::callState() const { return m_callState; }
QString SipCall::direction() const { return m_direction; }
int SipCall::duration() const { return m_duration; }
QString SipCall::callerName() const
{
    return m_callerName.isEmpty() ? m_remoteNumber : m_callerName;
}

bool SipCall::isMuted() const { return m_muted; }

void SipCall::setMuted(bool muted)
{
    if (m_muted == muted)
        return;
    m_muted = muted;
    applyMicTransmit();
    qDebug() << "[SipCall] Call #" << m_callId << (muted ? "muted" : "unmuted");
    emit mutedChanged();
}

// Connect/disconnect the capture device to every active audio stream.
void SipCall::applyMicTransmit()
{
    try {
        pj::CallInfo ci = getInfo();
        pj::AudDevManager &mgr = pj::Endpoint::instance().audDevManager();
        for (unsigned i = 0; i < ci.media.size(); i++) {
            if (ci.media[i].type == PJMEDIA_TYPE_AUDIO
                && ci.media[i].status == PJSUA_CALL_MEDIA_ACTIVE) {
                pj::AudioMedia audMedia = getAudioMedia(i);
                if (m_muted)
                    mgr.getCaptureDevMedia().stopTransmit(audMedia);
                else
                    mgr.getCaptureDevMedia().startTransmit(audMedia);
            }
        }
    } catch (const pj::Error &err) {
        qWarning() << "[SipCall] applyMicTransmit failed:" << err.info().c_str();
    }
}

void SipCall::sendDtmf(const QString &digits)
{
    try {
        dialDtmf(digits.toStdString());
        qDebug() << "[SipCall] DTMF" << digits << "on call #" << m_callId;
    } catch (const pj::Error &err) {
        qWarning() << "[SipCall] sendDtmf failed:" << err.info().c_str();
    }
}

void SipCall::makeCall(const std::string &dstUri, int ourId)
{
    pj::CallOpParam prm(true);
    prm.opt.audioCount = 1;
    prm.opt.videoCount = 0;
    pj::Call::makeCall(dstUri, prm);

    m_remoteNumber = QString::fromStdString(dstUri);
    int atPos = m_remoteNumber.indexOf(':');
    if (atPos >= 0) {
        QString afterScheme = m_remoteNumber.mid(atPos + 1);
        int atSign = afterScheme.indexOf('@');
        if (atSign >= 0) {
            m_remoteNumber = afterScheme.left(atSign);
        } else {
            m_remoteNumber = afterScheme;
        }
    }
    emit callerNameChanged();
    qDebug() << "[SipCall] Making call to" << m_remoteNumber;
}

void SipCall::answer()
{
    pj::CallOpParam prm(true);
    prm.statusCode = static_cast<pjsip_status_code>(200);
    pj::Call::answer(prm);
    qDebug() << "[SipCall] Answering call #" << m_callId;
}

void SipCall::setRemoteParty(const QString &number, const QString &displayName)
{
    m_remoteNumber = number;
    m_callerName = displayName;
    emit callerNameChanged();
}

void SipCall::hangup()
{
    pj::CallOpParam prm(true);
    pj::Call::hangup(prm);
    qDebug() << "[SipCall] Hanging up call #" << m_callId;
}

void SipCall::onCallState(pj::OnCallStateParam &prm)
{
    PJ_UNUSED_ARG(prm);
    try {
        pj::CallInfo ci = getInfo();
        m_callState = QString::fromStdString(ci.stateText);

        if (m_remoteNumber.isEmpty()) {
            std::string remoteUri = ci.remoteUri;
            QString uri = QString::fromStdString(remoteUri);
            int colon = uri.indexOf(':');
            if (colon >= 0) {
                QString after = uri.mid(colon + 1);
                int at = after.indexOf('@');
                if (at >= 0) {
                    m_remoteNumber = after.left(at);
                } else {
                    m_remoteNumber = after;
                }
            }
            emit callerNameChanged();
        }

        qDebug() << "[SipCall] Call #" << m_callId << "state:"
                 << m_callState << "remote:" << m_remoteNumber
                 << "code:" << ci.lastStatusCode;

        // Start duration timer when call is confirmed (connected)
        if (ci.state == PJSIP_INV_STATE_CONFIRMED) {
            QMetaObject::invokeMethod(this, [this]() {
                if (!m_durationTimer.isActive()) {
                    m_durationTimer.start();
                    qDebug() << "[SipCall] Duration timer started for call #" << m_callId;
                }
            }, Qt::QueuedConnection);
        }

        emit stateChanged();

        if (ci.state == PJSIP_INV_STATE_DISCONNECTED) {
            // Media is still alive here: dump RTP TX/RX packet counts and
            // remote/local media addresses for one-way-audio diagnosis.
            try {
                qDebug().noquote() << "[SipCall] Call #" << m_callId << "stats:\n"
                                   << QString::fromStdString(dump(true, "  "));
            } catch (const pj::Error &err) {
                qWarning() << "[SipCall] dump failed:" << err.info().c_str();
            }
            QMetaObject::invokeMethod(this, [this]() {
                m_durationTimer.stop();
            }, Qt::QueuedConnection);
            qDebug() << "[SipCall] Call #" << m_callId << "DISCONNECTED";
            emit disconnected();
        }
    } catch (const pj::Error &err) {
        qWarning() << "[SipCall] onCallState error:" << err.info().c_str();
    }
}

void SipCall::onCallMediaState(pj::OnCallMediaStateParam &prm)
{
    PJ_UNUSED_ARG(prm);
    try {
        pj::CallInfo ci = getInfo();
        for (unsigned i = 0; i < ci.media.size(); i++) {
            if (ci.media[i].type == PJMEDIA_TYPE_AUDIO
                && ci.media[i].status == PJSUA_CALL_MEDIA_ACTIVE) {
                pj::AudioMedia audMedia = getAudioMedia(i);
                pj::AudDevManager &mgr = pj::Endpoint::instance().audDevManager();
                if (!m_muted)
                    mgr.getCaptureDevMedia().startTransmit(audMedia);
                audMedia.startTransmit(mgr.getPlaybackDevMedia());
                qDebug() << "[SipCall] Audio connected for call #" << m_callId;

                try {
                    const int capId = mgr.getCaptureDev();
                    const int playId = mgr.getPlaybackDev();
                    qDebug() << "[SipCall] Capture device:" << capId
                             << QString::fromStdString(mgr.getDevInfo(capId).name)
                             << "| Playback device:" << playId
                             << QString::fromStdString(mgr.getDevInfo(playId).name);
                } catch (const pj::Error &err) {
                    qWarning() << "[SipCall] audio device info failed:" << err.info().c_str();
                }
            }
        }
    } catch (const pj::Error &err) {
        qWarning() << "[SipCall] onCallMediaState error:" << err.info().c_str();
    }
}

void SipCall::tickDuration()
{
    m_duration++;
    emit durationChanged();
}
