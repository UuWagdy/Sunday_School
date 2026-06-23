<div align="center">

<img src="introduction_website/public/logo.png" alt="Sunday School Logo" width="120" height="120" style="border-radius:20px"/>

# 🕊️ برنامج مدارس الأحد
### Sunday School Management System

**النظام البرمجي المتكامل لإدارة مدارس الأحد — Flutter (Android + Windows) + Website PWA**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-red?style=for-the-badge)](https://github.com/UuWagdy/Sunday_School)

---

🌐 **[الموقع التعريفي الرسمي](https://uuwagdy.github.io/Sunday_School/)** | 📱 **[تنزيل للأندرويد](https://www.mediafire.com/file/aa95rpi7jbi4vfv/Sunday_School.apk/file)** | 💻 **[تنزيل للكمبيوتر](https://www.mediafire.com/file/x20mjdbjo4lfp9c/Sunday_School.rar/file)**

</div>

---

## 📖 نبذة عن المشروع

**برنامج مدارس الأحد** هو نظام برمجي متكامل مصمم خصيصاً لخدمة الكنيسة القبطية الأرثوذكسية، يهدف إلى تسهيل إدارة مدارس الأحد بكل تفاصيلها من تسجيل الحضور والغياب، نقاط الطايو، تصميم الكارنيهات، الافتقاد، وإدارة الصندوق المالي.

---

## ✨ المميزات الرئيسية

| الميزة | الوصف |
|--------|--------|
| 📅 **الحضور والغياب** | تسجيل رقمي فوري بالـ QR مع دعم وضع الانصراف والفترة |
| 🪪 **مصمم الكارنيهات** | تحكم كامل في التصميم، الباركود، QR، والخلفيات |
| 🎟️ **نظام الطايو** | نقاط وكوبونات جوائز تشجيعية للمخدومين المتميزين |
| 📊 **السلوك والتقييم** | آلية حماية ذكية تمنع تصفير درجات الغائبين |
| 🏠 **الافتقاد والمتابعة** | تتبع الزيارات وتوزيع مهام الافتقاد الجغرافي |
| 💰 **الصندوق المالي** | إدارة الاشتراكات والمصروفات والتقارير المالية |
| 🎵 **الخوارس** | إدارة فصول الألحان والتسبحة وحضور الحفظ |
| 👥 **الرهوط** | مجموعات تنافسية صغيرة داخل الفصل |
| 📄 **التقارير والتحليلات** | تصدير PDF وExcel مع طباعة مجمعة لكل الفصول |
| 🔒 **إدارة المستخدمين** | صلاحيات متعددة المستويات وحسابات منفصلة لكل خادم |
| 💾 **النسخ الاحتياطي** | استرجاع البيانات بنقرة واحدة والترقية السنوية التلقائية |
| 🔗 **صلات القرابة** | ربط أفراد الأسرة وآباء الاعتراف |

---

## 📦 التحميل والتثبيت

### 📱 نسخة الأندرويد (Android APK)
```
https://www.mediafire.com/file/aa95rpi7jbi4vfv/Sunday_School.apk/file
```

### 💻 نسخة الكمبيوتر (Windows)

> ⚠️ **مهم:** يجب تحميل الملف المساعد أولاً قبل تشغيل البرنامج

1. **[تحميل الملف المساعد المطلوب](https://www.mediafire.com/file/ggfvkdy8vc9et2b/يجب+التنزيل+قبل+تشغيل+البرنامج.rar/file)** ← ثبّته أولاً
2. **[تحميل برنامج مدارس الأحد (.rar)](https://www.mediafire.com/file/x20mjdbjo4lfp9c/Sunday_School.rar/file)** ← فك الضغط وشغّله

### 🔑 بيانات الدخول الافتراضية
| اسم المستخدم | كلمة السر |
|:---:|:---:|
| `admin` | `1234` |

---

## 🗂️ هيكل المشروع

```
petros_pols_flutter/
├── lib/
│   ├── screens/          # شاشات التطبيق (17 شاشة)
│   ├── models/           # نماذج البيانات
│   ├── database/         # قاعدة بيانات SQLite
│   ├── services/         # الخدمات البرمجية
│   └── main.dart         # نقطة الدخول
├── assets/               # الأصول (اللوجو، الخطوط، الأيقونات)
├── introduction_website/ # الموقع التعريفي PWA
│   ├── index.html        # الصفحة الرئيسية
│   ├── manifest.json     # إعدادات PWA
│   ├── sw.js             # Service Worker
│   └── public/           # الصور والأيقونات
├── specs/                # مواصفات المشروع
└── README.md
```

---

## 🌐 الموقع التعريفي (PWA)

الموقع التعريفي متاح على:
**[https://uuwagdy.github.io/Sunday_School/](https://uuwagdy.github.io/Sunday_School/)**

يدعم التثبيت كـ Progressive Web App على الهاتف والكمبيوتر.

---

## 👨‍💻 فريق التطوير

<table align="center">
  <tr>
    <td align="center">
      <b>م. جورج منير</b><br>
      مبرمج النسخة الأصلية (C#)
    </td>
    <td align="center">
      <b>د. يوساب وجدي</b><br>
      تطوير Flutter + تصميم الموقع PWA<br>
      📞 01036976446
    </td>
  </tr>
</table>

---

## 📄 الترخيص

هذا المشروع مفتوح المصدر ومتاح تحت رخصة [MIT](LICENSE) — مجاني للاستخدام والتطوير والمشاركة.

---

<div align="center">

صُنع لأجل مجد المسيح وخدمة كنيسته المقدسة ❤️

**[⬆ العودة للأعلى](#)**

</div>
