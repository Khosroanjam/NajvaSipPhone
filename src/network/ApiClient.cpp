#include "ApiClient.h"
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QSettings>

static ApiClient *s_apiInstance = nullptr;

ApiClient *ApiClient::instance()
{
    if (!s_apiInstance)
        s_apiInstance = new ApiClient();
    return s_apiInstance;
}

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_syncStatus("disconnected")
{
    QSettings settings("SagharSIP", "SagharSIP");
    settings.beginGroup("Server");
    m_serverUrl = settings.value("url", "").toString();
    m_apiKey = settings.value("apiKey", "").toString();
    settings.endGroup();
}

void ApiClient::setServerUrl(const QString &url)
{
    if (m_serverUrl != url) {
        m_serverUrl = url;
        QSettings settings("SagharSIP", "SagharSIP");
        settings.beginGroup("Server");
        settings.setValue("url", url);
        settings.endGroup();
        m_token.clear();
        setSyncStatus("disconnected");
        emit serverUrlChanged();
        emit tokenChanged();
        emit authenticatedChanged(false);
    }
}

void ApiClient::setApiKey(const QString &key)
{
    if (m_apiKey != key) {
        m_apiKey = key;
        QSettings settings("SagharSIP", "SagharSIP");
        settings.beginGroup("Server");
        settings.setValue("apiKey", key);
        settings.endGroup();
        m_token.clear();
        setSyncStatus("disconnected");
        emit apiKeyChanged();
        emit tokenChanged();
        emit authenticatedChanged(false);
    }
}

void ApiClient::setToken(const QString &token)
{
    if (m_token != token) {
        m_token = token;
        setSyncStatus(token.isEmpty() ? "disconnected" : "syncing");
        emit tokenChanged();
        emit authenticatedChanged(!token.isEmpty());
    }
}

void ApiClient::setSyncStatus(const QString &status)
{
    if (m_syncStatus != status) {
        m_syncStatus = status;
        emit syncStatusChanged();
    }
}

bool ApiClient::isConfigured() const
{
    return !m_serverUrl.isEmpty() && !m_apiKey.isEmpty();
}

QNetworkReply *ApiClient::get(const QString &path, const QUrlQuery &query)
{
    QUrl url(m_serverUrl + path);
    if (!query.isEmpty())
        url.setQuery(query);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty())
        req.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());

    return m_nam->get(req);
}

QNetworkReply *ApiClient::post(const QString &path, const QJsonObject &body)
{
    QUrl url(m_serverUrl + path);
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty())
        req.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());

    return m_nam->post(req, QJsonDocument(body).toJson(QJsonDocument::Compact));
}

QNetworkReply *ApiClient::put(const QString &path, const QJsonObject &body)
{
    QUrl url(m_serverUrl + path);
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty())
        req.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());

    return m_nam->put(req, QJsonDocument(body).toJson(QJsonDocument::Compact));
}

QNetworkReply *ApiClient::del(const QString &path)
{
    QUrl url(m_serverUrl + path);
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty())
        req.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());

    return m_nam->deleteResource(req);
}

// ── Auth ─────────────────────────────────────────────────────────

void ApiClient::authenticate()
{
    if (!isConfigured())
        return;

    QJsonObject body;
    body["api_key"] = m_apiKey;

    QNetworkReply *reply = post("/api/v1/auth/token", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("auth", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        QString newToken = data["access_token"].toString();
        setToken(newToken);
    });
}

// ── Contacts ─────────────────────────────────────────────────────

void ApiClient::fetchContacts(const QString &search, int limit, int offset)
{
    QUrlQuery query;
    if (!search.isEmpty())
        query.addQueryItem("search", search);
    query.addQueryItem("limit", QString::number(limit));
    query.addQueryItem("offset", QString::number(offset));

    QNetworkReply *reply = get("/api/v1/contacts", query);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("contacts", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit contactsFetched(data["items"].toArray(), data["total"].toInt());
    });
}

void ApiClient::createContact(const QString &name, const QString &number,
                              const QString &email, const QVariantList &tags)
{
    QJsonObject body;
    body["name"] = name;
    body["number"] = number;
    body["email"] = email;
    QJsonArray tagArray;
    for (const auto &t : tags)
        tagArray.append(t.toString());
    body["tags"] = tagArray;

    QNetworkReply *reply = post("/api/v1/contacts", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("contacts/create", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit contactCreated(data);
    });
}

void ApiClient::updateContact(const QString &id, const QString &name, const QString &number,
                              const QString &email, const QVariantList &tags)
{
    QJsonObject body;
    body["name"] = name;
    body["number"] = number;
    body["email"] = email;
    QJsonArray tagArray;
    for (const auto &t : tags)
        tagArray.append(t.toString());
    body["tags"] = tagArray;

    QNetworkReply *reply = put("/api/v1/contacts/" + id, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("contacts/update", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit contactUpdated(data);
    });
}

void ApiClient::deleteContact(const QString &id)
{
    QNetworkReply *reply = del("/api/v1/contacts/" + id);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("contacts/delete", reply->errorString());
            return;
        }
        emit contactDeleted();
    });
}

// ── Call Logs ────────────────────────────────────────────────────

void ApiClient::createCallLog(const QString &number, const QString &name,
                              const QString &direction, int duration,
                              const QString &status,
                              const QDateTime &startedAt, const QDateTime &endedAt)
{
    QJsonObject body;
    body["number"] = number;
    body["name"] = name;
    body["direction"] = direction;
    body["duration"] = duration;
    body["status"] = status;
    body["started_at"] = startedAt.toUTC().toString(Qt::ISODate);
    if (endedAt.isValid())
        body["ended_at"] = endedAt.toUTC().toString(Qt::ISODate);

    QNetworkReply *reply = post("/api/v1/call-logs", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("call-logs/create", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit callLogCreated(data);
    });
}

// ── Notes ────────────────────────────────────────────────────────

void ApiClient::createNote(const QString &callLogId, const QString &text,
                           const QVariantList &tags)
{
    QJsonObject body;
    body["call_log_id"] = callLogId;
    body["text"] = text;
    QJsonArray tagArray;
    for (const auto &t : tags)
        tagArray.append(t.toString());
    body["tags"] = tagArray;

    QNetworkReply *reply = post("/api/v1/notes", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("notes/create", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit noteCreated(data);
    });
}

void ApiClient::fetchLastNotesByNumber(const QString &number, int limit)
{
    QString path = "/api/v1/numbers/" + number + "/notes";
    QUrlQuery query;
    query.addQueryItem("limit", QString::number(limit));

    QNetworkReply *reply = get(path, query);
    connect(reply, &QNetworkReply::finished, this, [this, reply, number]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("notes/last", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit lastNotesFetched(number, data["notes"].toArray());
    });
}

void ApiClient::fetchCallLogNotes(const QString &callLogId)
{
    QNetworkReply *reply = get("/api/v1/call-logs/" + callLogId + "/notes");
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("notes/call-log", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit callLogNotesFetched(data["items"].toArray());
    });
}

// ── Sync ─────────────────────────────────────────────────────────

void ApiClient::syncNow(const QJsonArray &contacts, const QJsonArray &callLogs,
                        const QJsonArray &notes)
{
    QJsonObject body;
    body["contacts"] = contacts;
    body["call_logs"] = callLogs;
    body["notes"] = notes;

    QNetworkReply *reply = post("/api/v1/sync", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            setSyncStatus("error");
            emit requestFailed("sync", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        setSyncStatus("idle");
        emit syncCompleted(
            data["contacts_synced"].toInt(),
            data["call_logs_synced"].toInt(),
            data["notes_synced"].toInt(),
            data["server_contacts"].toArray()
        );
    });
}

// ── Calendar ─────────────────────────────────────────────────────

void ApiClient::fetchCalendarSummary(const QString &startDate, const QString &endDate)
{
    QUrlQuery query;
    query.addQueryItem("start_date", startDate);
    query.addQueryItem("end_date", endDate);

    QNetworkReply *reply = get("/api/v1/calendar", query);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit requestFailed("calendar", reply->errorString());
            return;
        }
        QJsonObject data = QJsonDocument::fromJson(reply->readAll()).object();
        emit calendarSummaryFetched(data["days"].toArray());
    });
}
