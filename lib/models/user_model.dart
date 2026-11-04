import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum UserRole {
  superAdmin,
  institutionAdmin,
  coordinator,
  psychologist,
  speechTherapist,
  specialEducation,
  specialEdTeacher,
  teacher,
  reviewer,
  parent,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Tizim administratori';
      case UserRole.institutionAdmin:
        return 'Muassasa rahbari';
      case UserRole.coordinator:
        return 'Ta’lim koordinatori / Mas’ul';
      case UserRole.psychologist:
        return 'Amaliyotchi psixolog';
      case UserRole.speechTherapist:
        return 'Logoped-defektolog';
      case UserRole.specialEducation:
        return 'Maxsus pedagog (Defektolog)';
      case UserRole.specialEdTeacher:
        return 'Maxsus ta’lim o‘qituvchisi';
      case UserRole.teacher:
        return 'Fan o‘qituvchisi / Sinf rahbari';
      case UserRole.reviewer:
        return 'Kuzatuvchi / Metodist';
      case UserRole.parent:
        return 'Ota-ona / Vasiy';
    }
  }

  String get professionTitle {
    switch (this) {
      case UserRole.superAdmin:
        return 'Tizim boshqaruvi va ma’muriyat';
      case UserRole.institutionAdmin:
        return 'Muassasa rahbariyati va nazorat';
      case UserRole.coordinator:
        return 'ITR koordinatsiyasi va konsilium';
      case UserRole.psychologist:
        return 'Psixologiya va kognitiv diagnostika';
      case UserRole.speechTherapist:
        return 'Logopediya va nutq rivojlanishi';
      case UserRole.specialEducation:
        return 'Maxsus pedagogika va sensorika';
      case UserRole.specialEdTeacher:
        return 'Maxsus ta’lim va o‘quv dasturi';
      case UserRole.teacher:
        return 'Pedagogik monitoring va ta’lim';
      case UserRole.reviewer:
        return 'Metodik ekspertiza va monitoring';
      case UserRole.parent:
        return 'Farzand ta’limi va uy vazifalari';
    }
  }

  String get domainDescription {
    switch (this) {
      case UserRole.superAdmin:
        return 'Barcha muassasalar, kadrlar va monitoring qoidalari ustidan to‘liq ma’muriy nazorat.';
      case UserRole.institutionAdmin:
        return 'Maktab miqyosida o‘quvchilar, mutaxassislar yuklamasi va konsilium hisobotlari.';
      case UserRole.coordinator:
        return 'Ko‘p tarmoqli mutaxassislar xulosalarini umumlashtirish, ITR rejalari, monitoring va yo‘naltirishlarni muvofiqlashtirish.';
      case UserRole.psychologist:
        return 'Kognitiv jarayonlar, diqqat, xotira, emotsional-irodaviy soha va xulq-atvor diagnostikasi.';
      case UserRole.speechTherapist:
        return 'Tovushlar talaffuzi, artikulyatsion apparat, fonematik eshitish va bog‘lanishli nutq tahlili.';
      case UserRole.specialEducation:
        return 'Sensor integratsiya, mayda va yirik motorika, fazoviy mo‘ljal va hayotiy moslashuv.';
      case UserRole.specialEdTeacher:
        return 'Fanlar bo‘yicha bilim darajasini DTS talablari asosida baholash, topshiriqlar berish va individual ta’lim rejasini tuzish.';
      case UserRole.teacher:
        return 'Sinfdagi dars faoliyati, o‘quv motivatsiyasi, topshiriqlar ijrosi va ijtimoiy munosabatlar.';
      case UserRole.reviewer:
        return 'Tashqi tahliliy monitoring, ta’lim samaradorligi audit jurnali (faqat o‘qish huquqi).';
      case UserRole.parent:
        return 'Farzandning individual ta’lim rejasi, o‘zlashtirish sur’ati va mutaxassislar tavsiyalarini kuzatish.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.institutionAdmin:
        return Icons.account_balance_rounded;
      case UserRole.coordinator:
        return Icons.assignment_turned_in_rounded;
      case UserRole.psychologist:
        return Icons.psychology_rounded;
      case UserRole.speechTherapist:
        return Icons.record_voice_over_rounded;
      case UserRole.specialEducation:
        return Icons.extension_rounded;
      case UserRole.specialEdTeacher:
        return Icons.school_rounded;
      case UserRole.teacher:
        return Icons.menu_book_rounded;
      case UserRole.reviewer:
        return Icons.visibility_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.superAdmin:
        return AppColors.textPrimary; // Slate
      case UserRole.institutionAdmin:
        return AppColors.info; // Teal
      case UserRole.coordinator:
        return AppColors.purple; // Purple
      case UserRole.psychologist:
        return AppColors.primary; // Indigo
      case UserRole.speechTherapist:
        return AppColors.info; // Sky Blue
      case UserRole.specialEducation:
        return AppColors.warning; // Amber
      case UserRole.specialEdTeacher:
        return AppColors.primary; // Blue
      case UserRole.teacher:
        return AppColors.success; // Emerald
      case UserRole.reviewer:
        return AppColors.textMuted; // Slate Muted
      case UserRole.parent:
        return const Color(0xFFEA580C); // Orange
    }
  }

  bool get canCreateAssessments {
    return this != UserRole.reviewer && this != UserRole.parent;
  }

  List<String> get assessmentCategories {
    switch (this) {
      case UserRole.psychologist:
        return [
          'Kognitiv rivojlanish va tafakkur',
          'Diqqat barqarorligi va xotira',
          'Emotsional-irodaviy soha va xulq-atvor',
          'Ijtimoiy moslashuv va motivatsiya',
        ];
      case UserRole.speechTherapist:
        return [
          'Tovushlar talaffuzi va artikulyatsiya',
          'Fonematik idrok va eshitish tahlili',
          'Lug‘at boyligi va so‘z yasash',
          'Grammatik qurilish va bog‘lanishli nutq',
        ];
      case UserRole.specialEducation:
        return [
          'Sensor integratsiya va fazoviy mo‘ljal',
          'Mayda motorika va grafomotorika',
          'Yirik motorika va harakat koordinatsiyasi',
          'Hayotiy amaliy va o‘z-o‘ziga xizmat',
        ];
      case UserRole.specialEdTeacher:
        return [
          'Fanlar bo‘yicha bilim darajasi (DTS)',
          'O‘quv ko‘nikmalari (o‘qish, yozish, hisoblash)',
          'Topshiriqni mustaqil bajarish',
        ];
      case UserRole.teacher:
        return [
          'O‘quv motivatsiyasi va dars intizomi',
          'Dars topshiriqlarini o‘zlashtirish',
          'Sinf jamoasida ijtimoiy muloqot',
        ];
      case UserRole.coordinator:
      case UserRole.superAdmin:
      case UserRole.institutionAdmin:
        return [
          'Kompleks konsilium baholashi',
          'Kognitiv va intellektual rivojlanish',
          'Nutq va muloqot ko‘nikmalari',
          'Sensorika va motorika',
          'O‘quv-pedagogik faoliyat',
        ];
      case UserRole.reviewer:
      case UserRole.parent:
        return [];
    }
  }

  List<Map<String, dynamic>> get assessmentCriteria {
    switch (this) {
      case UserRole.psychologist:
        return [
          {'name': 'Diqqatni jamlash va yo‘naltirish qobiliyati', 'max': 25.0},
          {'name': 'Ko‘rgazmali-obrazli va mantiqiy tafakkur', 'max': 25.0},
          {'name': 'Xotira hajmi va eslab qolish tezligi', 'max': 25.0},
          {'name': 'Hissiy o‘zini boshqarish va intilish', 'max': 25.0},
        ];
      case UserRole.speechTherapist:
        return [
          {'name': 'Artikulyatsion apparat harakatchanligi', 'max': 25.0},
          {'name': 'Fonematik tahlil va tovush farqlash', 'max': 25.0},
          {'name': 'Aktiv va passiv so‘z boyligi hajmi', 'max': 25.0},
          {'name': 'Bog‘lanishli monologik va dialogik nutq', 'max': 25.0},
        ];
      case UserRole.specialEducation:
        return [
          {'name': 'Sensor qabul qilish (rang, hajm, shakl)', 'max': 25.0},
          {'name': 'Mayda motorika va barmoqlar epchilligi', 'max': 25.0},
          {'name': 'Fazoviy va tana sxemasini to‘g‘ri anglash', 'max': 25.0},
          {'name': 'Kundalik amaliy faoliyatda mustaqillik', 'max': 25.0},
        ];
      case UserRole.teacher:
        return [
          {'name': 'Dars mashg‘ulotlaridagi faollik', 'max': 25.0},
          {'name': 'O‘qituvchi ko‘rsatmalariga rioya qilish', 'max': 25.0},
          {'name': 'O‘quv qurollaridan to‘g‘ri foydalanish', 'max': 25.0},
          {'name': 'Sinfdoshlar bilan hamkorlik munosabati', 'max': 25.0},
        ];
      default:
        return [
          {'name': 'Ko‘rsatmalarni tushunish va idrok', 'max': 30.0},
          {'name': 'Mustaqil amaliy ijro samarasi', 'max': 35.0},
          {'name': 'Muloqot va ijtimoiy moslashuv', 'max': 35.0},
        ];
    }
  }

  String get code {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.institutionAdmin:
        return 'INSTITUTION_ADMIN';
      case UserRole.coordinator:
        return 'COORDINATOR';
      case UserRole.psychologist:
        return 'PSYCHOLOGIST';
      case UserRole.speechTherapist:
        return 'SPEECH_THERAPIST';
      case UserRole.specialEducation:
        return 'SPECIAL_EDUCATION';
      case UserRole.specialEdTeacher:
        return 'SPECIAL_ED_TEACHER';
      case UserRole.teacher:
        return 'TEACHER';
      case UserRole.reviewer:
        return 'REVIEWER';
      case UserRole.parent:
        return 'PARENT';
    }
  }

  static UserRole fromCode(String code) {
    switch (code) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'INSTITUTION_ADMIN':
        return UserRole.institutionAdmin;
      case 'COORDINATOR':
        return UserRole.coordinator;
      case 'PSYCHOLOGIST':
        return UserRole.psychologist;
      case 'SPEECH_THERAPIST':
        return UserRole.speechTherapist;
      case 'SPECIAL_EDUCATION':
        return UserRole.specialEducation;
      case 'SPECIAL_ED_TEACHER':
        return UserRole.specialEdTeacher;
      case 'TEACHER':
        return UserRole.teacher;
      case 'PARENT':
        return UserRole.parent;
      default:
        return UserRole.reviewer;
    }
  }
}

/// Lavozim va mutaxassislikni takrorlamasdan ko'rsatish
extension UserRoleTitle on UserModel {
  /// "Logoped-defektolog • Logoped-defektolog" o'rniga "Logoped-defektolog".
  /// Biri ikkinchisini o'z ichiga olsa — aniqrog'i (uzunrog'i) ko'rsatiladi.
  String get roleTitle {
    final role = this.role.label;
    final spec = specialization?.trim() ?? '';
    if (spec.isEmpty) return role;
    String norm(String v) =>
        v.toLowerCase().replaceAll(RegExp(r'[^a-z\u0400-\u04ff]'), '');
    final r = norm(role);
    final sp = norm(spec);
    if (r == sp) return role;
    if (sp.contains(r)) return spec;
    if (r.contains(sp)) return role;
    return '$role • $spec';
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String region;
  final String? district;
  final String? institutionId;
  final String? institutionName;
  final String? phone;
  final String? specialization;
  final String?
  qualificationCategory; // Oliy toifa, 1-toifa, 2-toifa, Mutaxassis
  final int experienceYears;
  final String? password;
  final bool isActive;
  final List<String> assignedStudentIds;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.region = 'Namangan viloyati',
    this.district,
    this.institutionId,
    this.institutionName,
    this.phone,
    this.specialization,
    this.qualificationCategory = 'Mutaxassis',
    this.experienceYears = 3,
    this.password,
    this.isActive = true,
    this.assignedStudentIds = const [],
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? region,
    String? district,
    String? institutionId,
    String? institutionName,
    String? phone,
    String? specialization,
    String? qualificationCategory,
    int? experienceYears,
    String? password,
    bool? isActive,
    List<String>? assignedStudentIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      region: region ?? this.region,
      district: district ?? this.district,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      qualificationCategory:
          qualificationCategory ?? this.qualificationCategory,
      experienceYears: experienceYears ?? this.experienceYears,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      assignedStudentIds: assignedStudentIds ?? this.assignedStudentIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role.code,
    'region': region,
    'district': district,
    'institutionId': institutionId,
    'institutionName': institutionName,
    'phone': phone,
    'specialization': specialization,
    'qualificationCategory': qualificationCategory,
    'experienceYears': experienceYears,
    'password': password,
    'isActive': isActive,
    'assignedStudentIds': assignedStudentIds,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    role: UserRoleExtension.fromCode(json['role'] as String),
    region: json['region'] as String? ?? 'Namangan viloyati',
    district: json['district'] as String?,
    institutionId: json['institutionId'] as String?,
    institutionName: json['institutionName'] as String?,
    phone: json['phone'] as String?,
    specialization: json['specialization'] as String?,
    qualificationCategory:
        json['qualificationCategory'] as String? ?? 'Mutaxassis',
    experienceYears: json['experienceYears'] as int? ?? 3,
    password: json['password'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    assignedStudentIds:
        (json['assignedStudentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}
