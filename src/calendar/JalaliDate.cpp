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

bool JalaliDate::isJalaliLeap(int jy)
{
    // Astronomical algorithm by Kazimierz M. Borkowski
    int breaks[] = {-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
                    1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178};
    int numBreaks = sizeof(breaks) / sizeof(breaks[0]);

    for (int i = 0; i < numBreaks; i++) {
        int dm = (breaks[i] - jy) * 31 + (breaks[i] < 0 ? 0 : 1);
        int rem = abs(dm) % 128;
        int remaining = 128 - rem;
        int daysInNextChange = dm > 0 ? remaining : (remaining == 128 ? 0 : rem);
        if (daysInNextChange == 0) return (i % 2 == 0);
    }
    return false;
}

void JalaliDate::gregorianToJalali(int gy, int gm, int gd, int &jy, int &jm, int &jd)
{
    // Borkowski algorithm
    // days since epoch
    int g_d_m[] = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};

    int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = 355666 + (365 * gy) + ((gy2 + 3) / 4) - ((gy2 + 99) / 100) + ((gy2 + 399) / 400) + gd + g_d_m[gm - 1];

    jy = -1595 + 33 * (days / 12053);
    int remaining = days % 12053;
    jy += 4 * (remaining / 1461);
    remaining %= 1461;

    if (remaining > 365) {
        jy += (remaining - 1) / 365;
        remaining = (remaining - 1) % 365;
    }

    if (remaining < 186) {
        jm = 1 + remaining / 31;
        jd = 1 + remaining % 31;
    } else {
        jm = 7 + (remaining - 186) / 30;
        jd = 1 + (remaining - 186) % 30;
    }
}

void JalaliDate::jalaliToGregorian(int jy, int jm, int jd, int &gy, int &gm, int &gd)
{
    // Borkowski algorithm (reverse)
    int days = (jy - 1) * 365;
    // leap years
    int leaps = 0;
    // count Jalali leap years before jy
    for (int y = 1; y < jy; y++) {
        if (isJalaliLeap(y)) leaps++;
    }
    days += leaps;

    // days in months before jm
    for (int m = 1; m < jm; m++) {
        if (m <= 6) days += 31;
        else if (m <= 11) days += 30;
        else days += (isJalaliLeap(jy) ? 30 : 29);
    }
    days += jd;

    // Convert from Jalali epoch (622-03-21 Gregorian) to Gregorian days
    // Approximate: Jalali starts ~21 March 622
    days += 79; // offset calibration

    // Convert days to Gregorian year
    gy = 1;
    while (true) {
        int yearDays = ((gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0) ? 366 : 365;
        if (days <= yearDays) break;
        days -= yearDays;
        gy++;
    }

    // Month and day
    static int monthDays[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if ((gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0) monthDays[1] = 29;
    gm = 0;
    while (gm < 12 && days > monthDays[gm]) {
        days -= monthDays[gm];
        gm++;
    }
    gm++;
    gd = days;
}
