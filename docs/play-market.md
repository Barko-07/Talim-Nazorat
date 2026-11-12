# Individ — Google Play'ga chiqarish tayyorgarligi

Holat: 2026-11-12. ✅ — tayyor, ⏳ — sizdan kerak, 🛠 — keyingi ish (ilova ekranlari).

## 1. Texnik tayyorgarlik

| | Nima | Holat |
|---|---|---|
| ✅ | Ilova identifikatori: `uz.individ.app` (birinchi yuklashdan keyin o‘zgarmaydi) | `android/app/build.gradle.kts` |
| ✅ | Internet ruxsati release versiyada (avval faqat debug’da bor edi — release serverga ulanmas edi) | `AndroidManifest.xml` |
| ✅ | Shifrlanmagan HTTP taqiqlangan, Google zaxirasiga nusxa olinmaydi (`allowBackup=false`) | `AndroidManifest.xml` |
| ✅ | Yuklash kaliti (upload key) yaratildi: `C:\Users\user\.individ\individ-upload.jks`, parol `android/key.properties` da (git’ga kirmaydi) | — |
| ⏳ | **Kalit nusxasi:** `individ-upload.jks` va `android/key.properties` ni fleshkaga ko‘chirib, xavfsiz joyda saqlang. Yo‘qolsa, Google’dan kalitni almashtirishni so‘rash kerak bo‘ladi (Play App Signing yoqilgan bo‘lsa mumkin) | — |
| ✅ | Android NDK 28.2.13676358 o‘rnatilgan | — |
| ✅ | Yig‘ish: `flutter build appbundle --release --dart-define=SERVER_MODE=true` → `build/app/outputs/bundle/release/app-release.aab`. Release ilova API_BASE_URL berilmasa ham https://individ.uz ga ulanadi | — |
| ✅ | Seans cookie’si release ilovada himoyalangan xotirada (flutter_secure_storage, Android Keystore) | `api_client.dart` |
| ✅ | Ilova ichida “Hisobni o‘chirish”: Sozlamalar → Hisobni o‘chirish (parol bilan) | `settings_screen.dart` |

## 2. Google Play talablari

| | Talab | Holat |
|---|---|---|
| ✅ | Hisobni o‘chirish — **veb orqali**: https://individ.uz/account-deletion.html | ishlaydi |
| ✅ | Hisobni o‘chirish — **ilova ichida** (Sozlamalar) | ishlaydi |
| ⏳ | Maxfiylik siyosati sahifasi: `web/privacy.html` tayyor, manzili https://individ.uz/privacy.html. Operator (mijoz tashkiloti) nomi, STIR, manzil, email kerak — `{{...}}` joylari to‘ldirilgach e’lon qilinadi | sizdan |
| ✅ | Google Play Developer hisobi ochilgan (to‘langan). Topshirishda ilova mijoz hisobiga App transfer orqali o‘tadi — `docs/handover.md` | — |
| ⏳ | Ilova sahifasi: qisqa/to‘liq tavsif, ikonka 512×512, kamida 2 ta skrinshot, feature graphic 1024×500 | keyin (store-screenshots skill bilan tayyorlayman) |
| ⏳ | Kontent reytingi so‘rovnomasi, maqsadli auditoriya: **kattalar (o‘qituvchi va mutaxassislar)** — ilova bolalar uchun emas, bolalar haqida | Play Console’da |
| ⏳ | Ichki sinov (Internal testing) → yopiq sinov: yangi shaxsiy hisoblar uchun 12 ta sinovchi 14 kun talab qilinadi; tashkilot hisobida bu talab yo‘q | Play Console’da |

## 3. Data safety (Ma’lumotlar xavfsizligi) shakli uchun javoblar

- **Ma’lumot yig‘iladimi?** Ha.
- **Shifrlanganmi (uzatishda)?** Ha — faqat HTTPS (TLS 1.2/1.3).
- **Foydalanuvchi o‘chirishni so‘ray oladimi?** Ha — ilova va veb orqali.
- **Uchinchi tomonlarga beriladimi?** Yo‘q. Reklama, analitika SDK yo‘q.
- Yig‘iladigan turlar:
  - *Shaxsiy ma’lumot:* ism, email, telefon — hisob yuritish uchun, majburiy.
  - *Kasbiy ma’lumot:* rol (mutaxassislik) va maktab — hisob uchun.
  - *Sog‘liq va boshqa sezgir ma’lumot (bolalar haqida):* tashxis, baholash natijalari, kuzatuvlar — ilova funksiyasi uchun, faqat mutaxassislar kiritadi, serverda AES-256 bilan shifrlangan, faqat bolaning jamoasi ko‘radi.
  - *Ilova faolligi:* kirishlar va o‘zgarishlar jurnali — xavfsizlik uchun.
- Joylashuv, kontaktlar, fotosuratlar, mikrofon — **yig‘ilmaydi**.

## 4. Maxfiylik siyosati — qoralama (⏳ belgilangan joylarni to‘ldiring)

> **Individ maxfiylik siyosati**
>
> Operator: ⏳ *[tashkilot to‘liq nomi, STIR]*, manzil: ⏳ *[manzil]*. Aloqa: ⏳ *[email]*.
>
> Individ — alohida ta’lim ehtiyojli bolalar bilan ishlaydigan pedagog va mutaxassislar uchun ish vositasi. Ilovadan faqat ta’lim muassasalari xodimlari foydalanadi.
>
> **Qanday ma’lumotlar:** xodimlar haqida — ism, email, telefon, kasbiy ma’lumotlar; bolalar haqida — mutaxassislar kiritadigan anketalar, baholash va mashg‘ulot natijalari, kuzatuvlar; xavfsizlik jurnali (kirishlar, o‘zgarishlar).
>
> **Nima uchun:** bolaning rivojlanishini kuzatish va mutaxassislar jamoasining ishini tashkil etish; hisob xavfsizligi.
>
> **Kim ko‘radi:** bola haqidagi ma’lumotni faqat o‘sha bola bilan ishlaydigan mutaxassislar jamoasi va nazorat uchun muassasa administratori ko‘radi. Ma’lumot uchinchi shaxslarga sotilmaydi va berilmaydi; reklama yo‘q.
>
> **Qayerda saqlanadi:** O‘zbekiston Respublikasi hududidagi serverda (O‘RQ-547 “Shaxsga doir ma’lumotlar to‘g‘risida” talabiga muvofiq). Sezgir ma’lumotlar shifrlangan holda saqlanadi, aloqa faqat HTTPS orqali.
>
> **Qancha saqlanadi:** xodim hisobi o‘chirilguncha. Bolalar bo‘yicha ish yozuvlari muassasaning hujjati sifatida muassasa belgilagan muddatda saqlanadi.
>
> **Huquqlaringiz:** o‘z ma’lumotlaringizni ko‘rish va tuzatish (Sozlamalar → Profilni tahrirlash), hisobni o‘chirish (https://individ.uz/account-deletion.html). Savollar: ⏳ *[email]*.

## 5. Oflayn rejim — qaror kerak

Server tayyor: har bir yozuvning versiyasi bor; oflayn qilingan o‘zgarish yuborilganda, agar orada boshqa kishi o‘zgartirgan bo‘lsa, server rad etib, joriy nusxani qaytaradi (`409 conflict`) — hech kimning ishi ustidan yozilmaydi.

**Muhim qarama-qarshilik:** siz “qurilmada ma’lumot qolmasin” degansiz. Oflayn ishlash uchun esa ma’lumotning bir qismi telefonda turishi shart. Taklif:

1. Faqat **telefon ilovasida** (veb-saytda emas) va faqat foydalanuvchi o‘z jamoasidagi bolalar.
2. Telefonda **shifrlangan** holda (kalit Android Keystore’da), boshqa ilovalar o‘qiy olmaydi.
3. **Chiqishda** va **7 kun** serverga ulanmasa — avtomatik o‘chiriladi.
4. Oflayn qilingan o‘zgarishlar navbatda turadi, internet kelganda yuboriladi; ziddiyat bo‘lsa — foydalanuvchiga ikkala nusxa ko‘rsatiladi.

Bu qarorni tasdiqlasangiz, ilova qismini (frontend) keyingi bosqichda qilaman.
