#include "SyncEngine.h"
#include "ApiClient.h"
#include "../Database.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantMap>
#include <QVariantList>
#include <QDateTime>
#include <QDebug>

static SyncEngine *s_syncInstance = nullptr;

SyncEngine *SyncEngine::instance()
{
    if (!s_syncInstance)
        s_syncInstance = new SyncEngine();
    return s_syncInstance;
}

SyncEngine::SyncEngine(QObject *parent)
    : QObject(parent)
    , m_api(ApiClient::instance())
    , m_timer(new QTimer(this))
    , m_enabled(true)
    , m_syncing(false)
    , m_intervalSecs(60)
{
    m_timer->setInterval(m_intervalSecs * 1000);
    connect(m_timer, &QTimer::timeout, this, &SyncEngine::doSync);
}

void SyncEngine::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        if (enabled && m_api->isAuthenticated())
            m_timer->start();
        else
            m_timer->stop();
        emit enabledChanged();
    }
}

void SyncEngine::setIntervalSecs(int secs)
{
    if (m_intervalSecs != secs) {
        m_intervalSecs = secs;
        m_timer->setInterval(secs * 1000);
        emit intervalSecsChanged();
    }
}

bool SyncEngine::isSyncing() const
{
    return m_syncing;
}

void SyncEngine::syncNow()
{
    if (!m_api->isConfigured() || !m_api->isAuthenticated()) {
        qWarning() << "[Sync] Not configured or authenticated, skipping sync";
        return;
    }
    doSync();
}

void SyncEngine::doSync()
{
    if (m_syncing)
        return;

    Database *db = Database::instance();
    m_syncing = true;
    emit syncingChanged();
    emit syncStarted();

    // Collect local contacts
    QVariantList localContacts = db->contacts();
    QJsonArray contactsArray;
    for (const auto &c : localContacts) {
        QVariantMap cm = c.toMap();
        QJsonObject co;
        co["name"] = cm["name"].toString();
        co["number"] = cm["number"].toString();
        co["email"] = cm["email"].toString();
        contactsArray.append(co);
    }

    // Collect recent call history (last 1000)
    QVariantList localCalls = db->callHistory(1000, 0);
    QJsonArray callsArray;
    for (const auto &cl : localCalls) {
        QVariantMap m = cl.toMap();
        QJsonObject co;
        co["number"] = m["number"].toString();
        co["name"] = m["name"].toString();
        co["direction"] = m["direction"].toString();
        co["duration"] = m["duration"].toInt();
        co["status"] = "completed";
        QDateTime ts = m["timestamp"].toDateTime();
        co["started_at"] = ts.toUTC().toString(Qt::ISODate);
        callsArray.append(co);
    }

    // Notes array (empty for bulk sync — notes are synced individually via createNote)
    QJsonArray notesArray;

    // Connect to sync completion
    QMetaObject::Connection *conn = new QMetaObject::Connection;
    *conn = connect(m_api, &ApiClient::syncCompleted, this,
        [this, conn](int, int, int, QJsonArray serverContacts) {
            disconnect(*conn);
            delete conn;

            // Merge server contacts into local DB
            Database *db = Database::instance();
            QVariantList localContacts = db->contacts();
            QSet<QString> localNumbers;
            for (const auto &c : localContacts)
                localNumbers.insert(c.toMap()["number"].toString());

            for (const auto &val : serverContacts) {
                QJsonObject sc = val.toObject();
                QString number = sc["number"].toString();
                if (!localNumbers.contains(number)) {
                    db->addContact(
                        sc["name"].toString(),
                        number,
                        sc["email"].toString()
                    );
                }
            }

            m_syncing = false;
            emit syncingChanged();
            emit syncFinished(true);
        });

    m_api->syncNow(contactsArray, callsArray, notesArray);
}
