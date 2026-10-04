#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QDateTime>
#include <QVariantList>
#include <QVariantMap>

class Database : public QObject
{
    Q_OBJECT
public:
    static Database *instance();

    Q_INVOKABLE void init();

    // Call history
    Q_INVOKABLE int addCallHistory(const QString &number, const QString &name,
                                   const QString &direction, int duration,
                                   const QDateTime &timestamp = QDateTime::currentDateTime());
    Q_INVOKABLE QVariantList callHistory(int limit = 100, int offset = 0);

    // Contacts
    Q_INVOKABLE int addContact(const QString &name, const QString &number,
                               const QString &email = QString(),
                               const QString &notes = QString());
    Q_INVOKABLE void updateContact(int id, const QString &name, const QString &number,
                                   const QString &email = QString(),
                                   const QString &notes = QString());
    Q_INVOKABLE void deleteContact(int id);
    Q_INVOKABLE QVariantList contacts(const QString &search = QString());
    Q_INVOKABLE QVariantMap contactById(int id);

    // Notes on calls
    Q_INVOKABLE void addNote(int callHistoryId, const QString &text);
    Q_INVOKABLE QVariantList notes(int callHistoryId);

    // CRM: last N notes for a phone number
    Q_INVOKABLE QVariantList lastNotesByNumber(const QString &number, int limit = 3);

    // Calendar: call history for a specific date
    Q_INVOKABLE QVariantList callHistoryByDate(const QString &dateStr);

signals:
    void callHistoryChanged();
    void contactsChanged();

private:
    explicit Database(QObject *parent = nullptr);
    ~Database();
    void createTables();
    QSqlDatabase m_db;
};

#endif // DATABASE_H
