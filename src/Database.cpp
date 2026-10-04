#include "Database.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>

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
        q.prepare("SELECT id, name, number, email, notes FROM contacts ORDER BY name");
    } else {
        q.prepare("SELECT id, name, number, email, notes FROM contacts "
                  "WHERE name LIKE :search OR number LIKE :search2 ORDER BY name");
        q.bindValue(":search", "%" + search + "%");
        q.bindValue(":search2", "%" + search + "%");
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
    q.prepare("SELECT id, name, number, email, notes FROM contacts WHERE id=:id");
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
    if (!q.exec())
        qWarning() << "[DB] addNote failed:" << q.lastError().text();
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
        "WHERE ch.number = :number "
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
    return result;
}
