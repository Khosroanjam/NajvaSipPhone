# تحلیل نرم‌افزار MicroSIP

## معرفی کلی

**MicroSIP** یک softphone متن‌باز (تحت لیسانس GPL v2) برای سیستم‌عامل ویندوز است که از پروتکل SIP برای تماس‌های صوتی و تصویری استفاده می‌کند. این نرم‌افزار با زبان C++ و فریم‌ورک MFC (Microsoft Foundation Classes) نوشته شده است.

- **وبسایت:** https://www.microsip.org
- **نسخه:** 3.22.3
- **آخرین بروزرسانی کپی‌رایت:** 2025

---

## ساختار پروژه

### فایل‌های اصلی (ریشه پروژه)

| فایل | نوع | توضیح |
|------|------|-------|
| `microsip.cpp` / `microsip.h` | Application | نقطه ورود برنامه، کلاس `CmicrosipApp`، مدیریت تک‌نمونه (Single Instance)، خط فرمان، crash handler |
| `mainDlg.cpp` / `mainDlg.h` | Main Dialog | پنجره اصلی، مدیریت تب‌ها، رویدادهای SIP، منوها |
| `global.cpp` / `global.h` | Globals | ساختارهای داده اصلی (`Account`, `Call`, `Contact`, `Shortcut`)، توابع کمکی SIP، enum پیام‌های سفارشی |
| `settings.cpp` / `settings.h` | Settings | `AccountSettings` شامل تمام تنظیمات برنامه، ذخیره/بارگذاری در فایل INI |
| `BaseDialog.cpp` / `BaseDialog.h` | Base | کلاس پایه برای تمام دیالوگ‌ها |
| `const.h` | Constants | ثابت‌های اصلی: نسخه، نام، کلید لایسنس، تعریف `_GLOBAL_VIDEO` |
| `define.h` | Defines | تعاریف گسترده: ابعاد پنجره، کدک‌های پیش‌فرض، رنگ‌ها، URLهای راهنما |
| `stdafx.h` | PCH | پیش‌کامپایل هدر (Precompiled Header) |

### دیالوگ‌ها (Dialog classes)

| فایل‌ها | کاربرد |
|---------|--------|
| `Dialer.cpp/.h` | صفحه شماره‌گیری |
| `Contacts.cpp/.h` | مدیریت مخاطبین |
| `Calls.cpp/.h` | مدیریت تماس‌ها |
| `MessagesDlg.cpp/.h` | پیام‌رسانی متنی |
| `AccountDlg.cpp/.h` | تنظیمات حساب SIP |
| `SettingsDlg.cpp/.h` | تنظیمات عمومی |
| `RinginDlg.cpp/.h` | پنجره تماس ورودی |
| `Preview.cpp/.h` | پیش‌نمایش ویدئو |
| `Transfer.cpp/.h` | انتقال تماس |
| `AddDlg.cpp/.h` | افزودن مخاطب |
| `AAOptionsDlg.cpp/.h` | گزینه‌های پاسخ خودکار |
| `FeatureCodesDlg.cpp/.h` | کدهای دستوری |
| `ShortcutsDlg.cpp/.h` | مدیریت میانبرها |

### کنترل‌های سفارشی (Custom Controls)

| فایل‌ها | توضیح |
|---------|-------|
| `ButtonDialer.cpp/.h` | دکمه‌های صفحه شماره‌گیری |
| `ButtonEx.cpp/.h` | دکمه پیشرفته |
| `ButtonBottom.cpp/.h` | دکمه پایین پنجره |
| `ButtonSafe.cpp/.h` | دکمه ایمن (ضد کلیک اشتباه) |
| `IconButton.cpp/.h` | دکمه با آیکون |
| `ClosableTabCtrl.cpp/.h` | تب با قابلیت بسته شدن |
| `LevelsSliderCtrl.cpp/.h` | اسلایدر سطح صدا |
| `StatusBar.cpp/.h` | نوار وضعیت |
| `CListCtrl_Sortable.cpp/.h` | لیست قابل مرتب‌سازی |
| `CListCtrl_SortItemsEx.cpp/.h` | لیست با مرتب‌سازی پیشرفته |

### کتابخانه‌های کمکی (`lib/`)

| فایل‌ها | کاربرد |
|---------|--------|
| `MSIP.cpp/.h` | wrapper اصلی برای pjsip، توالت کمکی SIP |
| `langpack.cpp/.h` | سیستم بومی‌سازی (Translate macro) |
| `jsoncpp/json/` | کتابخانه JSON داخلی |
| `Crypto.cpp/.h` | توابع رمزنگاری |
| `CSVFile.cpp/.h` | خواندن/نوشتن فایل CSV |
| `Markup.cpp/.h` | تجزیه XML |
| `Hid.cpp/.h` + `hidapi.h` | پشتیبانی از HID (Human Interface Device) |
| `MessageBoxX.cpp/.h` | MessageBox پیشرفته |
| `ModelessMessageBox.cpp/.h` | MessageBox غیرمودال |
| `StdioFileEx.cpp/.h` | فایل با قابلیت locking |
| `VisualStylesXP.cpp/.h` | پشتیبانی از استایل‌های بصری XP |
| `CListCtrl_ToolTip.cpp/.h` | ToolTip برای لیست‌ها |
| `CListCtrl_LabelTip.h` | LabelTip برای لیست‌ها |
| `ggets.cpp/.h` | دریافت ورودی از کنسول |
| `TemplateSmartPtr.h` | smart pointer قالبی |
| `CMask.cpp/.h` | ماسک ورودی |

### فایل‌های منابع (`res/`)

| فایل | توضیح |
|------|-------|
| `main.rc` | فایل منبع اصلی |
| `dialog.rc2` | منابع دیالوگ |
| `main.rc2` | منابع اصلی |
| `menu.rc2` | منابع منو |
| `icon.rc2` | منابع آیکون |
| تعداد زیاد فایل‌های `.ico` | آیکون‌های status، تماس،托盘 |

### سایر فایل‌ها

| فایل | توضیح |
|------|-------|
| `microsip.vcxproj` | فایل پروژه Visual Studio 2015 |
| `microsip.vcxproj.filters` | فیلترهای پروژه |
| `microsip.vcxproj.user` | تنظیمات کاربری پروژه |
| `packages.config` | وابستگی NuGet (WebView2) |
| `custom.manifest` | مانیفست (پشتیبانی از Windows 7 تا 10، DPI-aware) |
| `targetver.h` | نسخه هدف Windows (Windows 7) |
| `jumplist.cpp/.h` | Windows 7 JumpList |
| `MMNotificationClient.h` | تشخیص تغییر دستگاه‌های صوتی |
| `addons.cpp/.h` | hook برای افزودن قابلیت‌های سفارشی در زمان build |

---

## معماری نرم‌افزار

### زنجیره راه‌اندازی (Startup Chain)

```
microsip.exe
  └─ CmicrosipApp::InitInstance()  ← microsip.cpp
       ├─ accountSettings.Init()   ← بارگذاری تنظیمات
       ├─ SetUnhandledExceptionFilter(ExceptionFilter)  ← crash handler
       ├─ EnumWindows()            ← بررسی تک‌نمونه بودن
       ├─ CmainDlg (m_pMainWnd)    ← ساخت پنجره اصلی
       └─ mainDlg->OnCreated()     ← مقداردهی اولیه SIP
```

### پشته SIP

- **کتابخانه:** pjsip (pjsua-lib)
- **نحوه لینک:** استاتیک از طریق `#pragma comment(lib, "libpjproject-*")` در `mainDlg.h`
- **مسیر کتابخانه‌ها:** `..\pjlib\include`, `..\pjsip\include`, `..\pjmedia\include`, `..\pjnath\include`, `..\pjlib-util\include`
- **کتابخانه‌های شخص ثالث:** OpenSSL, SDL, FFmpeg, VPX, Opus, Silk, IPP, OpenCore AMR

### سیستم ارتباطی بین‌رشته‌ای

از `PostMessage` با پیام‌های سفارشی (`UM_*` در `global.h`) برای ارتباط بین رشته‌های SIP و ترد UI استفاده می‌شود:

```cpp
enum EUserWndMessages {
    UM_UPDATEWINDOWTEXT, UM_NOTIFYICON,
    UM_CALL_ANSWER, UM_CALL_HANGUP,
    UM_ON_INCOMING_CALL, UM_ON_CALL_STATE,
    UM_ON_PAGER, UM_ON_BUDDY_STATE,
    // ...
};
```

### سیستم تنظیمات

تمام تنظیمات در `AccountSettings` (ساختار در `settings.h`) ذخیره می‌شوند. این تنظیمات در فایل INI در مسیر `%APPDATA%\MicroSIP\` نگهداری می‌شوند.

### سیستم بومی‌سازی

از ماکرو `Translate()` استفاده می‌کند که در زمان اجرا جملات انگلیسی را با معادل زبان مقصد جایگزین می‌کند. فایل‌های زبان در زمان اجرا بارگذاری می‌شوند.

---

## build سیستم

- **ابزار:** Visual Studio 2015 (v140 toolset)
- **پلتفرم‌ها:** Win32 / x64
- **تنظیمات:** Debug / Release
- **MFC:** Static Link
- **Character Set:** Unicode
- **Precompiled Header:** `stdafx.h` (باید اولین include در هر فایل .cpp باشد)
- **وابستگی NuGet:** فقط `Microsoft.Web.WebView2` (برای نمایش محتوای وب)
- **هیچ تست، lint، typecheck یا CI در مخزن وجود ندارد**

### تنظیمات مهم build

```
PlatformToolset: v140
UseOfMfc: Static
MultiProcessorCompilation: true
RuntimeLibrary Debug: MultiThreadedDebug
RuntimeLibrary Release: MultiThreaded
```

---

## پارامترهای خط فرمان

| پارامتر | توضیح |
|---------|-------|
| `/reset` | حذف اطلاعات کاربر و تنظیمات |
| `/resetnoask` | حذف بدون تأیید |
| `/exit` | بستن نمونه در حال اجرا |
| `/minimized` | اجرا در system tray |
| `/answer` | پاسخ به تماس ورودی (کنترل از راه دور) |
| `/hangupall` | قطع تمام تماس‌ها (کنترل از راه دور) |

---

## ویژگی‌های کلیدی

1. **تماس صوتی و تصویری** (با قابلیت غیرفعال کردن ویدئو از طریق حذف `_GLOBAL_VIDEO`)
2. **پشتیبانی از DTLS** (از طریق `_GLOBAL_DTLS`)
3. **رمزنگاری SRTP**
4. **پشتیبانی از IPv6**
5. **تماس همگرایی (Conference)**
6. **انتقال تماس (Transfer)**
7. **پاسخ خودکار (Auto Answer)**
8. **ارسال پیام متنی**
9. **ضبط مکالمات**
10. **تشخیص تغییر شبکه**
11. **پشتیبانی از HID devices**
12. **Windows 7 JumpList**
13. **تشخیص تغییر دستگاه صوتی** (MMNotificationClient)
14. **میانبرهای قابل تنظیم**
15. **گزارش crash خودکار**

---

## تعاریف مهم (`const.h` / `define.h`)

| تعریف | مقدار | کاربرد |
|-------|-------|--------|
| `_GLOBAL_VERSION` | "3.22.3" | نسخه |
| `_GLOBAL_VIDEO` | - | فعال‌سازی ویدئو |
| `_GLOBAL_DTLS` | - | فعال‌سازی DTLS |
| `_GLOBAL_NAME` | "MicroSIP" | نام نرم‌افزار |
| `_GLOBAL_KEY` | "*********" | کلید لایسنس (placeholder) |
| `_GLOBAL_CODECS_ENABLED` | "PCMA/8000/1 PCMU/8000/1" | کدک‌های پیش‌فرض |
| `_GLOBAL_DIALER_CALL_COLOR` | RGB(76, 217, 100) | رنگ دکمه تماس (سبز) |
| `_GLOBAL_DIALER_END_COLOR` | RGB(255, 59, 48) | رنگ دکمه قطع تماس (قرمز) |

---

## مدیریت خطا (Crash Handling)

در `microsip.cpp` تابع `ExceptionFilter` به عنوان `SetUnhandledExceptionFilter` ثبت می‌شود:
- ذخیره `.txt` crash dump (شامل اطلاعات سیستم، نسخه، exception code)
- ذخیره `.dmp` (minidump)
- ارسال خودکار گزارش crash به `crash-report2.microsip.org`
- راه‌اندازی مجدد خودکار اگر pjsip در حال اجرا باشد
