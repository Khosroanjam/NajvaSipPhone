#include "JalaliDate.h"

JalaliDate::JalaliDate(QObject *parent)
    : QObject(parent)
    , m_jy(1403), m_jm(1), m_jd(1)
{
    setFromGregorian(QDate::currentDate());
}

int JalaliDate::weekday() const
{
    QDate g = toGregorian();
    int dayOfWeek = g.dayOfWeek(); // 1=Mon..7=Sun in Qt
    // Convert to Jalali: 0=Shanbe, 1=Yek.. 6=Jom'e
    return (dayOfWeek + 1) % 7;
}

QString JalaliDate::monthName() const
{
    static const char *names[] = {
        "", "Farvardin", "Ordibehesht", "Khordad", "Tir",
        "Mordad", "Shahrivar", "Mehr", "Aban", "Azar",
        "Dey", "Bahman", "Esfand"
    };
    return QString::fromUtf8(names[m_jm]);
}

QString JalaliDate::weekdayName() const
{
    static const char *names[] = {
        "Shanbe", "YekShanbe", "DoShanbe", "SeShanbe",
        "ChaharShanbe", "PanjShanbe", "Jome"
    };
    return QString::fromUtf8(names[weekday()]);
}

int JalaliDate::daysInMonth() const
{
    if (m_jm <= 6) return 31;
    if (m_jm <= 11) return 30;
    return isJalaliLeap(m_jy) ? 30 : 29;
}

QVariantList JalaliDate::monthNames()
{
    QVariantList list;
    const char *names[] = {
        "", "Farvardin", "Ordibehesht", "Khordad", "Tir",
        "Mordad", "Shahrivar", "Mehr", "Aban", "Azar",
        "Dey", "Bahman", "Esfand"
    };
    for (int i = 1; i <= 12; i++)
        list.append(QString::fromUtf8(names[i]));
    return list;
}

QVariantList JalaliDate::weekdayNames()
{
    QVariantList list;
    const char *names[] = {
        "Sh", "Ye", "Do", "Se", "Ch", "Pa", "Jo"
    };
    for (int i = 0; i < 7; i++)
        list.append(QString::fromUtf8(names[i]));
    return list;
}

QString JalaliDate::formatJalali(int jy, int jm, int jd)
{
    return QString("%1/%2/%3")
        .arg(jy, 4, 10, QChar('0'))
        .arg(jm, 2, 10, QChar('0'))
        .arg(jd, 2, 10, QChar('0'));
}

void JalaliDate::setFromGregorian(int gy, int gm, int gd)
{
    gregorianToJalali(gy, gm, gd, m_jy, m_jm, m_jd);
    emit dateChanged();
}

void JalaliDate::setFromGregorian(const QDate &date)
{
    setFromGregorian(date.year(), date.month(), date.day());
}

QDate JalaliDate::toGregorian() const
{
    int gy, gm, gd;
    jalaliToGregorian(m_jy, m_jm, m_jd, gy, gm, gd);
    return QDate(gy, gm, gd);
}

QString JalaliDate::toGregorianString(int jy, int jm, int jd)
{
    int gy, gm, gd;
    jalaliToGregorian(jy, jm, jd, gy, gm, gd);
    return QDate(gy, gm, gd).toString(Qt::ISODate);
}

QVariantMap JalaliDate::fromGregorianString(const QString &isoDate)
{
    QVariantMap result;
    // Accepts "yyyy-MM-dd" and full timestamps such as "yyyy-MM-ddTHH:mm:ss".
    const QDate date = QDate::fromString(isoDate.left(10), Qt::ISODate);
    if (!date.isValid())
        return result;
    int jy, jm, jd;
    gregorianToJalali(date.year(), date.month(), date.day(), jy, jm, jd);
    result["year"] = jy;
    result["month"] = jm;
    result["day"] = jd;
    return result;
}

QVariantMap JalaliDate::today()
{
    return fromGregorianString(QDate::currentDate().toString(Qt::ISODate));
}

int JalaliDate::monthLength(int jy, int jm)
{
    if (jm <= 6) return 31;
    if (jm <= 11) return 30;
    return isJalaliLeap(jy) ? 30 : 29;
}

int JalaliDate::weekdayOf(int jy, int jm, int jd)
{
    int gy, gm, gd;
    jalaliToGregorian(jy, jm, jd, gy, gm, gd);
    return (QDate(gy, gm, gd).dayOfWeek() + 1) % 7;  // Qt: 1=Mon..7=Sun
}

// Jalaali calendar (Borkowski's 33-year break table), as used by jalaali-js.
// Returns the Gregorian year in which Farvardin 1 of `jy` falls, the March
// day of that Nowruz, and the number of years since the last leap year
// (0 means `jy` itself is a leap year).
void JalaliDate::jalCal(int jy, int &gy, int &march, int &leap)
{
    static const int breaks[] = {-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
                                 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178};
    const int bl = sizeof(breaks) / sizeof(breaks[0]);

    gy = jy + 621;
    int leapJ = -14;
    int jp = breaks[0];
    int jump = 0;
    for (int i = 1; i < bl; i++) {
        const int jm = breaks[i];
        jump = jm - jp;
        if (jy < jm)
            break;
        leapJ += (jump / 33) * 8 + (jump % 33) / 4;
        jp = jm;
    }
    int n = jy - jp;
    leapJ += (n / 33) * 8 + ((n % 33) + 3) / 4;
    if (jump % 33 == 4 && jump - n == 4)
        leapJ += 1;

    const int leapG = gy / 4 - ((gy / 100 + 1) * 3) / 4 - 150;
    march = 20 + leapJ - leapG;

    if (jump - n < 6)
        n = n - jump + ((jump + 4) / 33) * 33;
    leap = (((n + 1) % 33) - 1) % 4;
    if (leap == -1)
        leap = 4;
}

bool JalaliDate::isJalaliLeap(int jy)
{
    int gy, march, leap;
    jalCal(jy, gy, march, leap);
    return leap == 0;
}

void JalaliDate::gregorianToJalali(int gy, int gm, int gd, int &jy, int &jm, int &jd)
{
    const qint64 jdn = QDate(gy, gm, gd).toJulianDay();
    jy = gy - 621;
    int calGy, march, leap;
    jalCal(jy, calGy, march, leap);
    qint64 k = jdn - QDate(calGy, 3, march).toJulianDay();

    if (k >= 0) {
        if (k <= 185) {
            jm = 1 + int(k / 31);
            jd = 1 + int(k % 31);
            return;
        }
        k -= 186;
    } else {
        // Before Nowruz: still in the previous Jalali year.
        jy -= 1;
        k += 179;
        if (leap == 1)
            k += 1;
    }
    jm = 7 + int(k / 30);
    jd = 1 + int(k % 30);
}

void JalaliDate::jalaliToGregorian(int jy, int jm, int jd, int &gy, int &gm, int &gd)
{
    int calGy, march, leap;
    jalCal(jy, calGy, march, leap);
    const qint64 jdn = QDate(calGy, 3, march).toJulianDay()
                     + (jm - 1) * 31 - (jm / 7) * (jm - 7) + jd - 1;
    const QDate date = QDate::fromJulianDay(jdn);
    gy = date.year();
    gm = date.month();
    gd = date.day();
}
