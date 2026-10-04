#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QTimer>

class ApiClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)
    Q_PROPERTY(QString token READ token NOTIFY tokenChanged)
    Q_PROPERTY(bool authenticated READ isAuthenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(QString syncStatus READ syncStatus NOTIFY syncStatusChanged)

public:
    static ApiClient *instance();

    QString serverUrl() const { return m_serverUrl; }
    void setServerUrl(const QString &url);

    QString apiKey() const { return m_apiKey; }
    void setApiKey(const QString &key);

    QString token() const { return m_token; }
    bool isAuthenticated() const { return !m_token.isEmpty(); }
    QString syncStatus() const { return m_syncStatus; }

    Q_INVOKABLE void authenticate();
    Q_INVOKABLE bool isConfigured() const;

    // Contacts
    Q_INVOKABLE void fetchContacts(const QString &search = QString(), int limit = 100, int offset = 0);
    Q_INVOKABLE void createContact(const QString &name, const QString &number,
                                   const QString &email = QString(),
                                   const QVariantList &tags = {});
    Q_INVOKABLE void updateContact(const QString &id, const QString &name, const QString &number,
                                   const QString &email = QString(),
                                   const QVariantList &tags = {});
    Q_INVOKABLE void deleteContact(const QString &id);

    // Call logs
    Q_INVOKABLE void createCallLog(const QString &number, const QString &name,
                                   const QString &direction, int duration,
                                   const QString &status = "completed",
                                   const QDateTime &startedAt = QDateTime::currentDateTime(),
                                   const QDateTime &endedAt = QDateTime());

    // Notes
    Q_INVOKABLE void createNote(const QString &callLogId, const QString &text,
                                const QVariantList &tags = {});
    Q_INVOKABLE void fetchLastNotesByNumber(const QString &number, int limit = 3);
    Q_INVOKABLE void fetchCallLogNotes(const QString &callLogId);

    // Sync
    Q_INVOKABLE void syncNow(const QJsonArray &contacts,
                             const QJsonArray &callLogs,
                             const QJsonArray &notes);

    // Calendar
    Q_INVOKABLE void fetchCalendarSummary(const QString &startDate, const QString &endDate);

signals:
    void serverUrlChanged();
    void apiKeyChanged();
    void tokenChanged();
    void authenticatedChanged(bool authenticated);
    void syncStatusChanged();

    // Response signals
    void contactsFetched(QJsonArray contacts, int total);
    void contactCreated(QJsonObject contact);
    void contactUpdated(QJsonObject contact);
    void contactDeleted();
    void callLogCreated(QJsonObject callLog);
    void noteCreated(QJsonObject note);
    void lastNotesFetched(QString number, QJsonArray notes);
    void callLogNotesFetched(QJsonArray notes);
    void syncCompleted(int contactsSynced, int callLogsSynced, int notesSynced,
                       QJsonArray serverContacts);
    void calendarSummaryFetched(QJsonArray days);

    // Error signals
    void requestFailed(const QString &endpoint, const QString &error);

private:
    explicit ApiClient(QObject *parent = nullptr);

    QNetworkReply *get(const QString &path, const QUrlQuery &query = QUrlQuery());
    QNetworkReply *post(const QString &path, const QJsonObject &body);
    QNetworkReply *put(const QString &path, const QJsonObject &body);
    QNetworkReply *del(const QString &path);

    void setToken(const QString &token);
    void setSyncStatus(const QString &status);

    QNetworkAccessManager *m_nam;
    QString m_serverUrl;
    QString m_apiKey;
    QString m_token;
    QString m_syncStatus;
};

#endif // APICLIENT_H
