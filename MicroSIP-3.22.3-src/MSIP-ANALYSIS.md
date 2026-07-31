# تحلیل فایل‌های MSIP.h و MSIP.cpp

## معرفی

فایل‌های `lib\MSIP.h` و `lib\MSIP.cpp` هسته‌ی ارتباط بین نرم‌افزار MicroSIP و پشته‌ی SIP (pjsip) هستند. این ماژول به عنوان یک لایه انتزاعی (abstraction layer) عمل می‌کند که توابع پرکاربرد تبدیل رشته، مدیریت URI، کار با شبکه، و توالت کمکی SIP را در بر می‌گیرد.

---

## ساختار MSIP.h

### ۱. کتابخانه‌های مورد نیاز

```cpp
#include "stdafx.h"
#include <pjsua-lib/pjsua.h>
#include <pjsua-lib/pjsua_internal.h>
```

- وابستگی مستقیم به کتابخانه pjsip (pjsua-lib)
- استفاده از نوع‌های `pj_str_t`, `pj_status_t`, `pj_time_val`

### ۲. ساختار SIPURI

```cpp
struct SIPURI {
    CString name;       // نام نمایشی (مثلاً "John Doe")
    CString user;       // نام کاربری (مثلاً "john")
    CString domain;     // دامنه (مثلاً "sip.example.com")
    CString parameters; // پارامترهای SIP (مثلاً ";transport=tcp")
    CString commands;   // دستورات اضافی
};
```

این ساختار برای تجزیه و ساخت URIهای SIP به کار می‌رود. مثلاً:
```
"John Doe" <sip:john@sip.example.com;transport=tcp>
```
تبدیل می‌شود به:
- name = "John Doe"
- user = "john"
- domain = "sip.example.com"
- parameters = ";transport=tcp"

### ۳. توابع سراسری (Global Functions)

| تابع | ورودی | خروجی | توضیح |
|------|-------|-------|-------|
| `msip_md5sum` | `CStringA&` یا `CString&` | `CStringA` | محاسبه MD5 (با استفاده از pj_md5) |
| `msip_audio_conf_set_volume` | `int val, bool mute` | `void` | تنظیم ولوم خروجی تمام تماس‌ها |
| `msip_audio_input_set_volume` | `int val, bool mute` | `void` | تنظیم ولوم میکروفن |
| `msip_verify_sip_url` | `CString& url` | `pj_status_t` | اعتبارسنجی URL ساده |
| `msip_get_duration` | `pj_time_val*` | `int` | تبدیل زمان pjsip به ثانیه |

### ۴. فضای نام MSIP

این namespace شامل ۳۰ تابع عمومی است که در دسته‌های زیر قرار می‌گیرند:

#### تبدیل رشته (Encoding/Decoding)

| تابع | توضیح |
|------|-------|
| `PjToStr` | تبدیل `pj_str_t` به `CString` (با گزینه UTF-8) |
| `Utf8DecodeUni` | تبدیل UTF-8 به Unicode (با pj_ansi_to_unicode) |
| `Utf8EncodeUni` | تبدیل Unicode به UTF-8 (از طریق WideCharToPjStr) |
| `UnicodeToAnsi` | تبدیل Unicode به ANSI (کپی کاراکتر به کاراکتر) |
| `AnsiToUnicode` | تبدیل ANSI به Unicode (کپی کاراکتر به کاراکتر) |
| `AnsiToWideChar` | تبدیل ANSI به WideChar (با API ویندوز) |
| `StringToPjString` | تبدیل CString به CStringA (با pj_unicode_to_ansi) |
| `StrToPjStr` | تبدیل CString به `pj_str_t` (اخطار: نیاز به free) |
| `WideCharToPjStr` | تبدیل CString به `char*` (اخطار: نیاز به free) |

#### مدیریت SIP URI

| تابع | توضیح |
|------|-------|
| `ParseSIPURI` | تجزیه رشته SIP به `SIPURI` |
| `BuildSIPURI` | ساختن رشته SIP از `SIPURI` |
| `IsIP` | بررسی اینکه آیا host یک آدرس IP است |
| `RemovePort` | حذف پورت از دامنه |

#### عملیات سیستمی

| تابع | توضیح |
|------|-------|
| `GetScreenRect` | دریافت ابعاد نمایشگر مجازی |
| `OpenURL` | باز کردن URL در مرورگر پیش‌فرض (از طریق rundll32) |
| `OpenFile` | باز کردن فایل با برنامه پیش‌فرض |
| `RunCmd` | اجرای یک دستور (با انتظار یا بدون انتظار) |
| `CommandLineToShell` | تجزیه خط فرمان به command + پارامترها |
| `PortKnock` | ارسال پالس UDP به پورت‌های مشخص (برای باز کردن firewall) |
| `IsConnectedToNetwork` | بررسی اتصال به شبکه (از طریق COM: INetworkListManager) |

#### متفرقه

| تابع | توضیح |
|------|-------|
| `GetErrorMessage` | تبدیل کد خطای pjsip به پیام قابل فهم |
| `ShowErrorMessage` | نمایش خطا در MessageBox |
| `GetDuration` | تبدیل ثانیه به رشته `HH:MM:SS` یا `MM:SS` |
| `IsPSTNNnmber` | بررسی اینکه شماره PSTN است (فقط ارقام، *، #) |
| `IniSectionExists` | بررسی وجود یک بخش در فایل INI |
| `Bin2String` | تبدیل باینری به هگزادسیمال |
| `String2Bin` | تبدیل هگزادسیمال به باینری |
| `FormatDateTime` | فرمت تاریخ (امروز: فقط زمان، غیرامروز: کامل) |
| `ExpandEnvironmentStrings` | گسترش متغیرهای محیطی در رشته |
| `GetSID` | دریافت SID کاربر جاری |

---

## تحلیل MSIP.cpp

### نحوه محاسبه MD5

```cpp
pj_md5_context ctx;
pj_uint8_t digest[16];
pj_md5_init(&ctx);
pj_md5_update(&ctx, pbContent, cbContent);
pj_md5_final(&ctx, digest);
```

از توابع pjsip برای هش MD5 استفاده می‌شود. دو overload وجود دارد:
1. ورودی `CStringA` (ANSI) → مستقیم هش می‌شود
2. ورودی `CString` (Unicode) → ابتدا به UTF-8 تبدیل می‌شود

### تنظیم ولوم صدا (`msip_audio_conf_set_volume`)

تمام تماس‌های فعال را enumerates کرده و برای هر کدام `pjsua_conf_adjust_rx_level` را تنظیم می‌کند. اگر mute=true باشد ولوم را صفر می‌کند.

### تنظیم ولوم میکروفن (`msip_audio_input_set_volume`)

منطق پیچیده‌ای دارد:
- اگر `swLevelAdjustment=true` باشد فقط از تنظیم نرم‌افزاری استفاده می‌کند
- اگر `micAmplification=true` باشد ولوم سخت‌افزاری را دو برابر می‌کند (تا ۵۰)
- بعد از ۵۰، از تابع توانی (`pow`) برای تقویت بیشتر استفاده می‌کند (غیرخطی)

### ParseSIPURI

الگوریتم تجزیه:
1. حذف `>` از انتها
2. پیدا کردن `sip:` و استخراج name (قسمت قبل از `sip:`)
3. پیدا کردن `@` و استخراج user
4. پیدا کردن `;` و استخراج domain و parameters
5. اگر `;` نبود، `?` را چک می‌کند
6. اگر هیچکدام نبود، بقیه domain است
7. `,` را برای commands جدا می‌کند

مثال:
```
"We rewewe" <sip:user@domain.com;param=val?cmd=xxx,yyy>
```
- name = "We rewewe"
- user = "user"
- domain = "domain.com"
- parameters = ";param=val?cmd=xxx"
- commands = ",yyy"

### PortKnock

قابلیت جالب Port Knocking:
1. دریافت host از تنظیمات یا سرور SIP
2. تبدیل hostname به IP (از طریق `gethostbyname`)
3. ایجاد UDP socket
4. ارسال بسته "knock" به هر پورت مشخص شده در تنظیمات
5. ۲۰۰ میلی‌ثانیه بین هر knock

### IsConnectedToNetwork

از COM و `INetworkListManager` برای تشخیص اتصال شبکه استفاده می‌کند. دو حالت:
- `checkInternet=false`: بررسی اتصال به هر شبکه
- `checkInternet=true`: بررسی اتصال به اینترنت

### مدیریت خطا

```cpp
CString MSIP::GetErrorMessage(pj_status_t status)
{
    if (status == 171039 || status == 171042) {
        str = "Invalid Number";
    }
    else if (status == PJSIP_EAUTHACCNOTFOUND) {
        str = "Account or credentials not found.";
    }
    else if (status == 130051) {
        str = "Unable to connect to remote server.";
    }
    else {
        pj_strerror(status, buf, PJ_ERR_MSG_SIZE);
        // حذف پرانتز از انتهای پیام
    }
    return Translate(...);
}
```

برخی کدهای خطا به صورت hardcoded ترجمه شده‌اند و بقیه از `pj_strerror` گرفته می‌شوند.

### OpenURL

```cpp
ShellExecute(NULL, NULL, _T("rundll32.exe"),
    _T("url.dll,FileProtocolHandler http://..."), NULL, SW_SHOWNORMAL);
```

از یک ترفند ویندوزی برای باز کردن URL استفاده می‌کند (به جای `ShellExecute(NULL, "open", url, ...)` مستقیم).

---

## نکات فنی مهم

1. **مدیریت حافظه**: توابع `StrToPjStr` و `WideCharToPjStr` از `malloc` استفاده می‌کنند و در کامنت خود نوشته‌اند "do not forget to free memory after call"

2. **وابستگی به pjsip**: این ماژول مستقیماً از توابع داخلی pjsip مانند `pj_md5_init`, `pj_unicode_to_ansi`, `pj_ansi_to_unicode`, `pj_strerror` استفاده می‌کند

3. **عدم استفاده از STL string**: تمام رشته‌ها با `CString` (MFC) مدیریت می‌شوند

4. **عدم استفاده از API مدرن ویندوز**: مثلاً `IsConnectedToNetwork` از `INetworkListManager` قدیمی استفاده می‌کند (قابل استفاده در ویندوز Vista+)

5. **Thread Safety**: هیچ lock یا مکانیزم همگام‌سازی در این فایل دیده نمی‌شود
