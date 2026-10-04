#ifndef JALALIDATE_H
#define JALALIDATE_H

#include <QObject>
#include <QDate>
#include <QString>
#include <QStringList>

class JalaliDate : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int year READ year NOTIFY dateChanged)
    Q_PROPERTY(int month READ month NOTIFY dateChanged)
    Q_PROPERTY(int day READ day NOTIFY dateChanged)
    Q_PROPERTY(int weekday READ weekday NOTIFY dateChanged)
    Q_PROPERTY(QString monthName READ monthName NOTIFY dateChanged)
    Q_PROPERTY(QString weekdayName READ weekdayName NOTIFY dateChanged)
    Q_PROPERTY(int daysInMonth READ daysInMonth NOTIFY dateChanged)

public:
    explicit JalaliDate(QObject *parent = nullptr);

    int year() const { return m_jy; }
    int month() const { return m_jm; }
    int day() const { return m_jd; }
    int weekday() const;  // 0=Shanbe, 1=Yekshanbe...6=Jom'e
    QString monthName() const;
    QString weekdayName() const;
    int daysInMonth() const;

    Q_INVOKABLE void setFromGregorian(int gy, int gm, int gd);
    Q_INVOKABLE void setFromGregorian(const QDate &date);
    Q_INVOKABLE QDate toGregorian() const;

    Q_INVOKABLE static QVariantList monthNames();
    Q_INVOKABLE static QVariantList weekdayNames();
    Q_INVOKABLE static QString formatJalali(int jy, int jm, int jd);

signals:
    void dateChanged();

private:
    static void gregorianToJalali(int gy, int gm, int gd, int &jy, int &jm, int &jd);
    static void jalaliToGregorian(int jy, int jm, int jd, int &gy, int &gm, int &gd);
    static bool isJalaliLeap(int jy);

    int m_jy, m_jm, m_jd;
};

#endif // JALALIDATE_H
