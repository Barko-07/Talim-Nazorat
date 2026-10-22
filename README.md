# TA’LIM NAZORAT — Alohida Ta’lim Ehtiyojlari Bo‘lgan Bolalar Rivojlanish Monitoringi (Flutter Ilovasi)

**TA’LIM NAZORAT** — bu O‘zbekiston Respublikasining Maktabgacha va maktab ta’limi vazirligi tasarrufidagi inklyuziv hamda ixtisoslashtirilgan ta’lim muassasalarida alohida ta’lim ehtiyojlari bo‘lgan (ATEB) bolalarning rivojlanish jarayonini kompleks, ko‘p tarmoqli va shaffof monitoring qilish uchun mo‘ljallangan **kross-platformali rasmiy Flutter ilovasi (Android, iOS, Windows, Web)**.

---

## 🏛️ Muhim Eslatma va Huquqiy Maqom
> [!IMPORTANT]
> **Pedagogik Monitoring Vositalari**: Ushbu platforma tibbiy tashxis qo‘yish vositasi emas. Platforma mutaxassislar (psixolog, logoped, defektolog, maxsus pedagog) tomonidan o‘tkazilgan pedagogik-psixologik baholash natijalarini tizimlashtirish, dinamikani tahlil qilish, Individual Ta’lim Rejalarini (ITR) monitoring qilish va mutaxassislar o‘rtasida hamkorlikni ta’minlovchi qaror qabul qilishni qo‘llab-quvvatlash tizimidir.

---

## 🛠️ Texnologik Stek (Flutter & Dart)

* **Freymvork va Platforma**: **Flutter 3.47.7** (Material 3 Design)
* **Dasturlash tili**: **Dart 3.13.5**
* **Holat boshqaruvi (State Management)**: **Provider 6.1.5**
* **Ma’lumotlar bazasi (Database)**: **Mahalliy Mustaqil Baza (Local SharedPreferences Persistence + In-memory relational index)**
  * **Zero Supabase**: Tizimda Supabase mutlaqo ishlatilmagan, tashqi API kalitlarsiz va oylik to‘lovlarsiz 100% oflayn rejimda ham to‘liq ishlaydi.
* **Tipografiya va Dizayn**: Google Fonts (`Plus Jakarta Sans`), maxsus korporativ HSL palitrasi (`Teal`, `Navy`, `Emerald`, `Amber`, `Rose`).
* **Grafiklar va Vizualizatsiya**: `fl_chart` (Oylik rivojlanish dinamikasi, mezonlar taqsimoti).
* **Testlash**: Flutter Test Framework (`flutter test` — barcha unit va model testlari 100% muvaffaqiyatli).

---

## 👥 Demo Foydalanuvchilar va Rollar (RBAC)

Ilovada barcha mutaxassislar uchun standart parol: **`Parol2026!`**

| Rol | Login (Email) | Huquq va Doira |
| :--- | :--- | :--- |
| **Tizim administratori** | `admin@talim.uz` | Barcha muassasalar, audit jurnali, monitoring qoidalari va foydalanuvchilar nazorati |
| **Muassasa rahbari** | `maktab14.admin@talim.uz` | 14-Inklyuziv maktab o‘quvchilari, mutaxassislari, yuklama va hisobotlari |
| **Amaliyotchi psixolog** | `psixolog@talim.uz` | Psixologik baholashlar, ITR maqsadlari, kognitiv mashg‘ulotlar |
| **Logoped-defektolog** | `logoped@talim.uz` | Nutqiy rivojlanish baholashlari, artikulyatsiya darslari |
| **Maxsus pedagog (Defektolog)** | `defektolog@talim.uz` | Sensor va motorika mashg‘ulotlari, defektologik monitoring |
| **Fan o‘qituvchisi / Sinf rahbari** | `oqituvchi@talim.uz` | Dars davomati, o‘quv mashg‘ulotlari, ITR progressi |
| **Kuzatuvchi / Metodist** | `kuzatuvchi@talim.uz` | Faqat o‘qish huquqi (Read-only analitika va hisobotlar) |

*(Eslatma: Kirish oynasida rollarni 1 ta klik bilan tanlab tezkor kirish tugmalari ham mavjud).*

---

## 🚀 Ilovani Ishga Tushirish

### 1. Bog‘liqliklarni yuklab olish:
```bash
flutter pub get
```

### 2. Avtomatlashtirilgan testlarni tekshirish:
```bash
flutter test
```

### 3. Ilovani ishga tushirish:

**Brauzerda (Chrome/Edge):**
```bash
flutter run -d chrome
```

**Windows Kompyuter dasturi sifatida (Desktop):**
```bash
flutter run -d windows
```

**Veb uchun tayyor build yig‘ish (Production Web):**
```bash
flutter build web
```

---

## 📋 Ilovaning Asosiy Ekranlari va Imkoniyatlari

1. **Kirish ekrani (`LoginScreen`)**:
   - Xavfsiz kirish va barcha 7 ta mutaxassis rollarini 1 klikda almashtirish.
2. **Boshqaruv paneli (`DashboardScreen`)**:
   - 4 ta asosiy KPI kartasi (*Jami o‘quvchilar*, *Faol ITR rejalari*, *Bu oygi darslar*, *O‘rtacha o‘sish*).
   - `fl_chart` orqali animatsiyali oylik rivojlanish grafigi.
   - Diqqat talab qilinuvchi o‘quvchilar ogohlantirish paneli.
   - Kutilayotgan darslar va so‘nggi baholashlar lentasi.
3. **Bolalar elektron reyestri (`StudentsListScreen`)**:
   - O‘quvchilarni ism, sinf va ehtiyoj bo‘yicha tezkor qidiruv va filtrlash.
   - Yangi o‘quvchini ro‘yxatga olish shakli (`AddStudentScreen`).
4. **8 ta bo‘limli Bolaning Elektron Pasporti (`StudentDetailScreen`)**:
   - *1. Umumiy ma’lumot* (Tashxis, yordam darajasi, vasiylar kontaktlari).
   - *2. Baholashlar* (Rubrika ballari, mezonlar, mutaxassis xulosalari).
   - *3. Mashg‘ulotlar tarixi* (O‘tkazilgan darslar, davomat, qaydlar).
   - *4. Individual ta’lim rejasi (ITR)* (Maqsadlar, muddatlar, interaktiv progress slaydri).
   - *5. Rivojlanish dinamikasi* (Ko‘rsatkichlar o‘sishi va barqarorligi).
   - *6. Yo‘naltirishlar* (Mutaxassislararo va komissiyaga yo‘llanmalar).
   - *7. Hujjatlar* (PMPK xulosasi, tibbiy ko‘rik ma’lumotnomasi).
   - *8. Faoliyat tarixi (Audit)* (Har bir kiritilgan o‘zgarish vaqti va muallifi).
5. **Baholashlar va Diagnostika (`AssessmentsListScreen` & `NewAssessmentScreen`)**:
   - Kategoriyalar (Nutq, Kognitiv, Sensor, Ijtimoiy) bo‘yicha ko‘p mezonli rubrika baholash.
6. **Mashg‘ulotlar va Davomat (`SessionsScreen`)**:
   - Darslarni rejalashtirish, davomat belgilash (*Bajarildi*, *Qatnashmadi*).
7. **Individual Ta’lim Rejasi (`IepListScreen` & `IepPrintScreen`)**:
   - Maqsadlar ijrosi va rasmiy davlat standarti bo‘yicha A4 bosma blankasi formatidagi ko‘rinish.
8. **Avtomatlashtirilgan Monitoring (`MonitoringScreen`)**:
   - 5 ta doimiy qoida bo‘yicha muammoli holatlarni aniqlash (*Dars qoldirish*, *Kechikkan baholash*, *Stagnatsiya*, *Ko‘rsatkich pasayishi*, *Muddati o‘tgan maqsadlar*).
   - Signallarni qabul qilish va yechim kiritish dialogi.
9. **Hisobotlar va Analitika (`ReportsScreen`)**:
   - Muassasa yig‘ma hisoboti va CSV formatida eksport.
10. **Mutaxassislar katalogi (`SpecialistsScreen`)**:
    - Xodimlar dars yuklamasi va o‘quvchilar soni.
11. **Sozlamalar (`SettingsScreen`)**:
    - Profil, tezkor rol almashtirish va O‘zR O‘RQ-547 qonuniga muvofiq maxfiylik ko‘rsatkichlari.
