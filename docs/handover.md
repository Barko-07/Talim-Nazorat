# Individ — mijozga topshirish rejasi

Maqsad: ish tugagach, hamma kalit va kirish huquqlari **mijozda** bo‘ladi, ishlab chiquvchi kompyuterida **hech narsa qolmaydi**, eski kalitlar esa endi hech narsani ocholmaydi.

Asosiy qoida: kalit nusxasini berib, eskisini o‘chirish yetarli emas. Nusxa qayerdadir qolgan bo‘lishi mumkin. Shuning uchun har bir kirish **mijozning yangi kaliti bilan almashtiriladi**, eskisi serverda **bekor qilinadi**.

## 1. Hozir qayerda nima bor

| Nima | Hozir qayerda | Nima ochadi |
|---|---|---|
| SSH kalit `individ_server` | `C:\Users\user\.ssh\` | Serverga kirish (`mistaker0908` hisobi) |
| Server hisobining sudo paroli | Sizning xotirangizda | Serverda to‘liq boshqaruv |
| Zaxira shifrlash kaliti `backup-key.txt` | `C:\Users\user\.individ\` | Barcha zaxira nusxalarni (bolalar ma’lumotini) ochadi |
| Zaxira nusxalar | `C:\Users\user\.individ\backups\` + serverda `~/offsite` | Shifrlangan baza nusxalari |
| “Individ backup pull” vazifasi | Windows Task Scheduler | Har kuni zaxirani shu kompyuterga tortadi |
| Android yuklash kaliti `individ-upload.jks` + `android/key.properties` | `C:\Users\user\.individ\`, loyiha papkasi | Play’ga ilova yangilanishini yuklash |
| Serverdagi `.env` (ma’lumot shifrlash kaliti, baza paroli, pochta paroli, seans siri) | Faqat serverda `/srv/individ/server/.env` | Bazadagi shifrlangan ma’lumot, pochta |
| Play Console hisobi | Sizning Google hisobingiz | Ilova sahifasi va chiqarilishi |
| Domen `individ.uz` va DNS | Registrator hisobi (sizda) | Sayt manzili |
| VDS provayder hisobi | Sizda | Server, qayta o‘rnatish, konsol |
| Ilovadagi super admin hisobi | Sizning emailingiz | Ilovani to‘liq boshqarish |
| Kod (git) | Shu kompyuter, GitHub | Manba kodi |
| Claude Code suhbat yozuvlari | `C:\Users\user\.claude\projects\c--Users-user-Desktop-APP\` | Server manzili, tuzilishi haqida ma’lumot (parollar yo‘q) |

## 2. Topshirish tartibi (mijoz bilan birga, bir kunda)

1. **Mijozning server hisobi.** Mijoz o‘z kompyuterida SSH kalit yaratadi (`ssh-keygen -t ed25519`). Serverda unga alohida hisob ochiladi, kaliti qo‘shiladi, sudo paroli **mijozning o‘zi** kiritadi.
2. **Deploy huquqi mijozga.** `/etc/sudoers.d/91-individ-deploy` va `individ-deploy` skriptidagi `mistaker0908` mijoz hisobiga almashtiriladi.
3. **Yangi zaxira kaliti.** Mijoz o‘z kompyuterida `age-keygen` qiladi. Serverdagi `individ-backup` yangi ochiq kalitga o‘tkaziladi. Yangi zaxira olinib, mijoz kompyuterida ochilishi tekshiriladi (`pull-backups.ps1` u yerda o‘rnatiladi).
4. **Server sirlarini almashtirish.** Baza paroli, pochta paroli, seans siri yangilanadi. Ma’lumot shifrlash kaliti ham almashtiriladi. Buning uchun butun bazani yangi kalit bilan qayta shifrlaydigan buyruq kerak. U hali yozilmagan: topshirishdan oldin qo‘shiladi.
5. **Android kaliti.** `individ-upload.jks` va `key.properties` mijozga shifrlangan fleshkada beriladi. Yoki yaxshirog‘i: Play Console’da “Upload key reset” qilinib, mijoz o‘z kalitini yaratadi.
6. **Play Console.** Ilova mijozning developer hisobiga **App transfer** orqali o‘tkaziladi (Play Console → Settings → App transfer). Yoki mijoz hisobi “Owner” qilib qo‘shiladi.
7. **Domen, VDS, pochta hisoblari.** Egalik mijozga o‘tkaziladi, parollarni mijoz o‘zgartiradi.
8. **Ilova super admini.** Mijozning emaili bilan yangi super admin yaratiladi. Sizning hisobingiz o‘chiriladi (`/api/auth/account/delete`).
9. **Kod.** GitHub repozitoriyasi mijozga topshiriladi (Transfer ownership).

## 3. Eski kirishlarni bekor qilish (mijoz tekshiradi)

- Serverda `mistaker0908` hisobi o‘chiriladi: `sudo userdel -r mistaker0908`. Shu bilan `individ_server` kaliti va `~/offsite` ham yo‘qoladi.
- Mijoz serverga o‘z kaliti bilan kira olishini, eski kalit bilan **kira olmasligini** tekshiradi.
- Eski zaxira kaliti bilan yangi zaxira ochilmasligi tekshiriladi.

## 4. Bu kompyuterni tozalash (oxirgi qadam)

Faqat 2- va 3-bo‘limlar tugab, mijoz hammasi ishlayotganini tasdiqlagandan keyin:

```powershell
schtasks /Delete /TN "Individ backup pull" /F
Remove-Item -Recurse -Force "$env:USERPROFILE\.individ"
Remove-Item -Force "$env:USERPROFILE\.ssh\individ_server", "$env:USERPROFILE\.ssh\individ_server.pub"
Remove-Item -Force "C:\Users\user\Desktop\APP\android\key.properties"
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\projects\c--Users-user-Desktop-APP"
```

Keyin Windows savatchasini (Recycle Bin) bo‘shating. SSD’da o‘chirilgan fayl izi qolishi mumkin, lekin 3-bo‘limdan keyin u kalitlar baribir hech narsani ochmaydi. Shuning uchun almashtirish o‘chirishdan muhimroq.

## 5. Topshirishgacha xavfsiz saqlash

Topshirish kunigacha kalitlarning **yagona** nusxasi shu kompyuterda. Kompyuter buzilsa yoki yo‘qolsa:
- `backup-key.txt` yo‘qolsa, hamma zaxira nusxalar o‘qib bo‘lmaydigan bo‘ladi.
- `individ-upload.jks` yo‘qolsa, Play’da kalitni tiklash so‘rovi kerak (bir necha kun).
- SSH kalit yo‘qolsa, serverga faqat provayder konsoli orqali kirish mumkin.

Shuning uchun **vaqtinchalik** nusxa kerak: `C:\Users\user\.individ\` va `android/key.properties` shifrlangan fleshkada (BitLocker To Go). Topshirish kuni shu fleshka mijozga beriladi yoki tozalanadi.
