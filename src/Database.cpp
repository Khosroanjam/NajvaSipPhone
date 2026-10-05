#include "Database.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QHash>
#include <QStringList>

static Database *s_dbInstance = nullptr;

Database *Database::instance()
{
    if (!s_dbInstance)
        s_dbInstance = new Database();
    return s_dbInstance;
}

Database::Database(QObject *parent)
    : QObject(parent)
{
}

Database::~Database()
{
    if (m_db.isOpen())
        m_db.close();
}

void Database::init()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    QString dbPath = dataPath + "/sagharsip.db";

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "[DB] Cannot open database:" << m_db.lastError().text();
        return;
    }

    qDebug() << "[DB] Database opened:" << dbPath;
    createTables();
}

void Database::createTables()
{
    QSqlQuery q(m_db);

    q.exec("CREATE TABLE IF NOT EXISTS call_history ("
           "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  number TEXT NOT NULL,"
           "  name TEXT DEFAULT '',"
           "  direction TEXT NOT NULL,"    // 'incoming' or 'outgoing'
           "  duration INTEGER DEFAULT 0,"
           "  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP"
           ")");

    q.exec("CREATE TABLE IF NOT EXISTS contacts ("
           "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  name TEXT NOT NULL,"
           "  number TEXT NOT NULL,"
           "  email TEXT DEFAULT '',"
           "  notes TEXT DEFAULT '',"
           "  created DATETIME DEFAULT CURRENT_TIMESTAMP"
           ")");

    q.exec("CREATE TABLE IF NOT EXISTS notes ("
           "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  call_history_id INTEGER,"
           "  text TEXT NOT NULL,"
           "  created DATETIME DEFAULT CURRENT_TIMESTAMP,"
           "  FOREIGN KEY(call_history_id) REFERENCES call_history(id)"
           ")");
}

int Database::addCallHistory(const QString &number, const QString &name,
                              const QString &direction, int duration,
                              const QDateTime &timestamp)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO call_history (number, name, direction, duration, timestamp) "
              "VALUES (:number, :name, :direction, :duration, :timestamp)");
    q.bindValue(":number", number);
    q.bindValue(":name", name);
    q.bindValue(":direction", direction);
    q.bindValue(":duration", duration);
    q.bindValue(":timestamp", timestamp);
    if (!q.exec()) {
        qWarning() << "[DB] addCallHistory failed:" << q.lastError().text();
        return -1;
    }
    emit callHistoryChanged();
    return q.lastInsertId().toInt();
}

QVariantList Database::callHistory(int limit, int offset)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT id, number, name, direction, duration, timestamp "
              "FROM call_history ORDER BY timestamp DESC LIMIT :limit OFFSET :offset");
    q.bindValue(":limit", limit);
    q.bindValue(":offset", offset);
    if (q.exec()) {
        while (q.next()) {
            QVariantMap row;
            row["id"] = q.value(0);
            row["number"] = q.value(1);
            row["name"] = q.value(2);
            row["direction"] = q.value(3);
            row["duration"] = q.value(4);
            row["timestamp"] = q.value(5);
            result.append(row);
        }
    }
    resolveContactNames(result);
    return result;
}

int Database::addContact(const QString &name, const QString &number,
                         const QString &email, const QString &notes)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO contacts (name, number, email, notes) "
              "VALUES (:name, :number, :email, :notes)");
    q.bindValue(":name", name);
    q.bindValue(":number", number);
    q.bindValue(":email", email);
    q.bindValue(":notes", notes);
    if (!q.exec()) {
        qWarning() << "[DB] addContact failed:" << q.lastError().text();
        return -1;
    }
    emit contactsChanged();
    return q.lastInsertId().toInt();
}

void Database::updateContact(int id, const QString &name, const QString &number,
                             const QString &email, const QString &notes)
{
    QSqlQuery q(m_db);
    q.prepare("UPDATE contacts SET name=:name, number=:number, email=:email, notes=:notes "
              "WHERE id=:id");
    q.bindValue(":name", name);
    q.bindValue(":number", number);
    q.bindValue(":email", email);
    q.bindValue(":notes", notes);
    q.bindValue(":id", id);
    if (!q.exec())
        qWarning() << "[DB] updateContact failed:" << q.lastError().text();
    emit contactsChanged();
}

void Database::deleteContact(int id)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM contacts WHERE id=:id");
    q.bindValue(":id", id);
    if (!q.exec())
        qWarning() << "[DB] deleteContact failed:" << q.lastError().text();
    emit contactsChanged();
}

QVariantList Database::contacts(const QString &search)
{
    QVariantList result;
    QSqlQuery q(m_db);
    if (search.isEmpty()) {
        q.prepare("SELECT id, name, number, COALESCE(email, ''), COALESCE(notes, '') FROM contacts ORDER BY name COLLATE NOCASE");
    } else {
        q.prepare("SELECT id, name, number, COALESCE(email, ''), COALESCE(notes, '') FROM contacts "
                  "WHERE name LIKE :search OR number LIKE :search2 OR email LIKE :search3 "
                  "ORDER BY name COLLATE NOCASE");
        q.bindValue(":search", "%" + search + "%");
        q.bindValue(":search2", "%" + search + "%");
        q.bindValue(":search3", "%" + search + "%");
    }
    if (q.exec()) {
        while (q.next()) {
            QVariantMap row;
            row["id"] = q.value(0);
            row["name"] = q.value(1);
            row["number"] = q.value(2);
            row["email"] = q.value(3);
            row["notes"] = q.value(4);
            result.append(row);
        }
    }
    return result;
}

QVariantMap Database::contactById(int id)
{
    QVariantMap row;
    QSqlQuery q(m_db);
    q.prepare("SELECT id, name, number, COALESCE(email, ''), COALESCE(notes, '') FROM contacts WHERE id=:id");
    q.bindValue(":id", id);
    if (q.exec() && q.next()) {
        row["id"] = q.value(0);
        row["name"] = q.value(1);
        row["number"] = q.value(2);
        row["email"] = q.value(3);
        row["notes"] = q.value(4);
    }
    return row;
}

void Database::addNote(int callHistoryId, const QString &text)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO notes (call_history_id, text) VALUES (:call_history_id, :text)");
    q.bindValue(":call_history_id", callHistoryId);
    q.bindValue(":text", text);
    if (!q.exec()) {
        qWarning() << "[DB] addNote failed:" << q.lastError().text();
        return;
    }
    emit notesChanged();
}

QVariantList Database::notes(int callHistoryId)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT id, text, created FROM notes WHERE call_history_id=:cid ORDER BY created");
    q.bindValue(":cid", callHistoryId);
    if (q.exec()) {
        while (q.next()) {
            QVariantMap row;
            row["id"] = q.value(0);
            row["text"] = q.value(1);
            row["created"] = q.value(2);
            result.append(row);
        }
    }
    return result;
}

QVariantList Database::lastNotesByNumber(const QString &number, int limit)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare(
        "SELECT n.id, n.text, n.created, ch.direction, ch.duration, ch.timestamp "
        "FROM notes n "
        "JOIN call_history ch ON n.call_history_id = ch.id "
        // Same suffix match as normalizeNumber(), so dial prefixes don't hide history.
        "WHERE substr(ch.number, -10) = substr(:number, -10) "
        "ORDER BY ch.timestamp DESC "
        "LIMIT :limit"
    );
    q.bindValue(":number", number);
    q.bindValue(":limit", limit);
    if (q.exec()) {
        while (q.next()) {
            QVariantMap row;
            row["id"] = q.value(0);
            row["text"] = q.value(1);
            row["created"] = q.value(2);
            row["direction"] = q.value(3);
            row["duration"] = q.value(4);
            row["timestamp"] = q.value(5);
            result.append(row);
        }
    }
    return result;
}

QVariantList Database::callHistoryByDate(const QString &dateStr)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare(
        "SELECT id, number, name, direction, duration, timestamp "
        "FROM call_history "
        "WHERE DATE(timestamp) = :date "
        "ORDER BY timestamp DESC"
    );
    q.bindValue(":date", dateStr);
    if (q.exec()) {
        while (q.next()) {
            QVariantMap row;
            row["id"] = q.value(0);
            row["number"] = q.value(1);
            row["name"] = q.value(2);
            row["direction"] = q.value(3);
            row["duration"] = q.value(4);
            row["timestamp"] = q.value(5);
            result.append(row);
        }
    }
    attachNotes(result);
    resolveContactNames(result);
    return result;
}

void Database::attachNotes(QVariantList &calls)
{
    if (calls.isEmpty())
        return;

    // Ids come from our own integer column, so inlining them is safe.
    QStringList ids;
    for (const QVariant &call : std::as_const(calls))
        ids << QString::number(call.toMap().value("id").toInt());

    QHash<int, QVariantList> notesByCall;
    QSqlQuery q(m_db);
    if (!q.exec("SELECT call_history_id, text, created FROM notes "
                "WHERE call_history_id IN (" + ids.join(',') + ") ORDER BY created")) {
        qWarning() << "[DB] attachNotes failed:" << q.lastError().text();
        return;
    }
    while (q.next()) {
        QVariantMap note;
        note["text"] = q.value(1);
        note["created"] = q.value(2);
        notesByCall[q.value(0).toInt()].append(note);
    }

    for (QVariant &call : calls) {
        QVariantMap row = call.toMap();
        row["notes"] = notesByCall.value(row.value("id").toInt());
        call = row;
    }
}

QVariantList Database::callStatsByDateRange(const QString &fromDate, const QString &toDate)
{
    QVariantList result;
    QSqlQuery q(m_db);
    // "Missed" mirrors CallHistory.qml: an explicit 'missed' row or an
    // incoming call that never connected.
    q.prepare(
        "SELECT DATE(timestamp) AS day, COUNT(*), "
        "  SUM(CASE WHEN direction = 'incoming' THEN 1 ELSE 0 END), "
        "  SUM(CASE WHEN direction = 'outgoing' THEN 1 ELSE 0 END), "
        "  SUM(CASE WHEN direction = 'missed' "
        "            OR (direction = 'incoming' AND duration = 0) THEN 1 ELSE 0 END), "
        "  SUM(duration) "
        "FROM call_history "
        "WHERE DATE(timestamp) BETWEEN :from AND :to "
        "GROUP BY day ORDER BY day"
    );
    q.bindValue(":from", fromDate);
    q.bindValue(":to", toDate);
    if (!q.exec()) {
        qWarning() << "[DB] callStatsByDateRange failed:" << q.lastError().text();
        return result;
    }
    while (q.next()) {
        QVariantMap row;
        row["date"] = q.value(0);
        row["total"] = q.value(1).toInt();
        row["incoming"] = q.value(2).toInt();
        row["outgoing"] = q.value(3).toInt();
        row["missed"] = q.value(4).toInt();
        row["duration"] = q.value(5).toInt();
        result.append(row);
    }
    return result;
}

QVariantList Database::searchCalls(const QString &text, int limit)
{
    QVariantList result;
    const QString needle = text.trimmed();
    if (needle.isEmpty())
        return result;

    // Treat the user's text literally: escape LIKE wildcards with '!'.
    QString escaped = needle;
    escaped.replace("!", "!!").replace("%", "!%").replace("_", "!_");
    const QString pattern = "%" + escaped + "%";

    QSqlQuery q(m_db);
    q.prepare(
        "SELECT ch.id, ch.number, ch.name, ch.direction, ch.duration, ch.timestamp "
        "FROM call_history ch "
        "WHERE ch.number LIKE :p1 ESCAPE '!' "
        "   OR ch.name LIKE :p2 ESCAPE '!' "
        "   OR EXISTS (SELECT 1 FROM notes n "
        "              WHERE n.call_history_id = ch.id AND n.text LIKE :p3 ESCAPE '!') "
        "   OR EXISTS (SELECT 1 FROM contacts c "
        "              WHERE c.name LIKE :p4 ESCAPE '!' "
        "                AND substr(c.number, -10) = substr(ch.number, -10)) "
        "ORDER BY ch.timestamp DESC "
        "LIMIT :limit"
    );
    q.bindValue(":p1", pattern);
    q.bindValue(":p2", pattern);
    q.bindValue(":p3", pattern);
    q.bindValue(":p4", pattern);
    q.bindValue(":limit", limit);
    if (!q.exec()) {
        qWarning() << "[DB] searchCalls failed:" << q.lastError().text();
        return result;
    }
    while (q.next()) {
        QVariantMap row;
        row["id"] = q.value(0);
        row["number"] = q.value(1);
        row["name"] = q.value(2);
        row["direction"] = q.value(3);
        row["duration"] = q.value(4);
        row["timestamp"] = q.value(5);
        result.append(row);
    }
    attachNotes(result);
    resolveContactNames(result);
    return result;
}

QString Database::normalizeNumber(const QString &number)
{
    QString digits;
    digits.reserve(number.size());
    for (const QChar ch : number) {
        if (ch.isDigit())
            digits.append(QChar('0' + ch.digitValue()));  // also folds Persian/Arabic digits
    }
    if (digits.isEmpty())
        return number.trimmed();  // e.g. a SIP username
    return digits.size() > 10 ? digits.right(10) : digits;
}

QHash<QString, QVariantMap> Database::contactsByNormalizedNumber()
{
    QHash<QString, QVariantMap> map;
    QSqlQuery q(m_db);
    if (!q.exec("SELECT id, name, number, COALESCE(email, ''), COALESCE(notes, '') FROM contacts ORDER BY id")) {
        qWarning() << "[DB] contactsByNormalizedNumber failed:" << q.lastError().text();
        return map;
    }
    while (q.next()) {
        const QString key = normalizeNumber(q.value(2).toString());
        if (key.isEmpty() || map.contains(key))
            continue;  // first saved entry wins for duplicates
        QVariantMap row;
        row["id"] = q.value(0);
        row["name"] = q.value(1);
        row["number"] = q.value(2);
        row["email"] = q.value(3);
        row["notes"] = q.value(4);
        map.insert(key, row);
    }
    return map;
}

QVariantMap Database::contactByNumber(const QString &number)
{
    const QString key = normalizeNumber(number);
    if (key.isEmpty())
        return {};
    return contactsByNormalizedNumber().value(key);
}

// Names are resolved when calls are read, not when they are logged, so a
// contact saved or renamed later shows up on its past calls too.
void Database::resolveContactNames(QVariantList &calls)
{
    if (calls.isEmpty())
        return;
    const QHash<QString, QVariantMap> contacts = contactsByNormalizedNumber();
    if (contacts.isEmpty())
        return;
    for (QVariant &call : calls) {
        QVariantMap row = call.toMap();
        const auto it = contacts.constFind(normalizeNumber(row.value("number").toString()));
        if (it == contacts.constEnd())
            continue;
        row["name"] = it->value("name");
        row["contactId"] = it->value("id");
        call = row;
    }
}
