#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QDateTime>
#include <QVariantList>
#include <QVariantMap>
#include <QHash>

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
    // Phonebook entry for a dialled/received number, matched on normalizeNumber().
    // Empty map when the number is not in the phonebook.
    Q_INVOKABLE QVariantMap contactByNumber(const QString &number);

    // Digits only, reduced to the last 10 digits for long numbers, so
    // "09121234567", "+989121234567" and a dial-prefixed "909121234567"
    // all compare equal. Short numbers (extensions, *codes) stay exact.
    Q_INVOKABLE static QString normalizeNumber(const QString &number);

    // Notes on calls
    Q_INVOKABLE void addNote(int callHistoryId, const QString &text);
    Q_INVOKABLE QVariantList notes(int callHistoryId);

    // CRM: last N notes for a phone number
    Q_INVOKABLE QVariantList lastNotesByNumber(const QString &number, int limit = 3);

    // Calendar: call history for a specific date ("yyyy-MM-dd"), each row
    // carrying its after-call notes in a "notes" list
    Q_INVOKABLE QVariantList callHistoryByDate(const QString &dateStr);

    // Calendar: per-day call counts between two dates (inclusive, "yyyy-MM-dd").
    // One row per day that has calls: date, total, incoming, outgoing, missed, duration
    Q_INVOKABLE QVariantList callStatsByDateRange(const QString &fromDate, const QString &toDate);

    // Calendar: calls whose number, name or note text contains `text`, newest first
    Q_INVOKABLE QVariantList searchCalls(const QString &text, int limit = 200);

signals:
    void callHistoryChanged();
    void contactsChanged();
    void notesChanged();

private:
    explicit Database(QObject *parent = nullptr);
    ~Database();
    void createTables();
    void attachNotes(QVariantList &calls);
    void resolveContactNames(QVariantList &calls);
    QHash<QString, QVariantMap> contactsByNormalizedNumber();
    QSqlDatabase m_db;
};

#endif // DATABASE_H
