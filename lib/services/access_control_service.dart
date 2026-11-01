import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/referral_model.dart';

class AccessControlService {
  static final AccessControlService _instance =
      AccessControlService._internal();
  factory AccessControlService() => _instance;
  AccessControlService._internal();

  // ==================== MAKTAB / TASHKILOT BO'YICHA IZOLYATSIYA ====================
  /// Foydalanuvchi va o'quvchi bir xil muassasaga tegishlimi?
  bool isSameInstitution(
    UserModel user,
    String? institutionId,
    String? institutionName,
  ) {
    if (user.role == UserRole.superAdmin) {
      return true; // Tizim administratori butun viloyatni ko'radi
    }
    if (user.institutionId != null && institutionId != null) {
      if (user.institutionId == institutionId) return true;
    }
    if (user.institutionName != null && institutionName != null) {
      // Faqat to'liq mos nom. Qisman moslik ("1" ↔ "14-sonli maktab") boshqa
      // maktab bolalarini ochib qo'yardi.
      final uName = _normalizeName(user.institutionName!);
      final tName = _normalizeName(institutionName);
      if (uName.isNotEmpty && uName == tName) return true;
    }
    return false;
  }

  String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // ==================== O'QUVCHILARGA RUXSAT ====================
  /// O'quvchi ma'lumotlarini ko'rish ruxsati
  bool canViewStudent(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;

    // Maktab izolyatsiyasi tekshiruvi
    final sameSchool = isSameInstitution(
      user,
      student.institutionId,
      student.institutionName,
    );
    if (!sameSchool) return false;

    // Maktab rahbari, koordinator yoki sinf o'qituvchisi butun maktab o'quvchilarini ko'ra oladi
    if (user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator ||
        user.role == UserRole.reviewer) {
      return true;
    }

    // Mutaxassislar (Psixolog, Logoped, Defektolog, O'qituvchi):
    // Biriktirilgan o'quvchilarni yoki o'z maktabining ro'yxatidagi bolalarni ko'rish
    return true;
  }

  /// O'quvchi faqat ushbu mutaxassisga bevosita biriktirilganmi?
  bool isStudentAssignedTo(UserModel user, StudentModel student) {
    if (student.assignedSpecialistIds.contains(user.id)) return true;
    if (user.assignedStudentIds.contains(student.id)) return true;
    if (student.coordinatorId == user.id) return true;
    return false;
  }

  /// O'quvchi anketasini yaratish yoki tahrirlash huquqi
  bool canEditStudent(UserModel user, StudentModel? student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator) {
      if (student == null) return true;
      return isSameInstitution(
        user,
        student.institutionId,
        student.institutionName,
      );
    }
    if (user.role == UserRole.teacher) {
      // Sinf rahbari o'z sinfidagi o'quvchini tahrirlay oladi
      if (student == null) return true;
      return isSameInstitution(
        user,
        student.institutionId,
        student.institutionName,
      );
    }
    return false;
  }

  /// Maxfiy tibbiy yoki psixologik ma'lumotlarni ko'rish (Least-privilege)
  bool canViewSensitiveMedical(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.psychologist ||
        user.role == UserRole.specialEducation ||
        user.role == UserRole.coordinator;
  }

  /// Maxfiy psixologik kuzatuvni ko'rish: faqat muallif, psixologlar va tizim administratori.
  /// (Psixologik sir — o'qituvchi va kuzatuvchilar ko'rmaydi)
  bool canViewConfidentialObservation(UserModel user, String psychologistId) {
    if (!user.isActive) return false;
    if (user.id == psychologistId) return true;
    return user.role == UserRole.psychologist ||
        user.role == UserRole.superAdmin;
  }

  /// O'quvchini arxivlash yoki holatini o'zgartirish
  bool canArchiveStudent(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (user.role == UserRole.institutionAdmin) {
      return isSameInstitution(
        user,
        student.institutionId,
        student.institutionName,
      );
    }
    return false;
  }

  // ==================== BAHOLASHLARGA RUXSAT ====================
  /// Baholash o'tkazish ruxsati
  bool canCreateAssessment(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.reviewer || user.role == UserRole.parent) {
      return false;
    }
    if (!isSameInstitution(
      user,
      student.institutionId,
      student.institutionName,
    )) {
      return false;
    }

    // Mutaxassislar (Psixolog, Logoped, Defektolog, O'qituvchi, Koordinator, Admin)
    return user.role.canCreateAssessments;
  }

  /// Baholashni o'chirish yoki o'zgartirish (Faqat muallif yoki Admin)
  bool canModifyAssessment(UserModel user, AssessmentModel assessment) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (assessment.specialistId == user.id) return true;
    if (user.role == UserRole.institutionAdmin) return true;
    return false;
  }

  // ==================== MASHG'ULOTLARGA RUXSAT ====================
  /// Mashg'ulot rejalashtirish
  bool canScheduleSession(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.reviewer || user.role == UserRole.parent) {
      return false;
    }
    return isSameInstitution(
      user,
      student.institutionId,
      student.institutionName,
    );
  }

  /// Mashg'ulotni bajarilgan deb belgilash (Faqat mas'ul mutaxassis yoki Admin)
  bool canCompleteSession(UserModel user, SessionModel session) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin) {
      return true;
    }
    return session.specialistId == user.id;
  }

  // ==================== INDIVIDUAL TA'LIM REJASI (ITR) ====================
  /// ITR yaratish yoki tahrirlash
  bool canManageIep(UserModel user, IndividualEducationPlanModel? plan) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator) {
      return true;
    }
    if (plan != null && plan.responsibleTeacherId == user.id) return true;
    return false;
  }

  /// ITR maqsadlaridagi progressni yangilash
  bool canUpdateObjectiveProgress(
    UserModel user,
    IndividualEducationPlanModel plan,
    PlanObjectiveModel objective,
  ) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator) {
      return true;
    }
    if (plan.responsibleTeacherId == user.id) return true;
    if (objective.responsibleSpecialistId == user.id) return true;
    return false;
  }

  // ==================== YO'NALTIRISHLAR (REFERRALS) ====================
  /// Bolani boshqa mutaxassisga yo'naltirish
  bool canCreateReferral(UserModel user) {
    if (!user.isActive) return false;
    return user.role != UserRole.reviewer && user.role != UserRole.parent;
  }

  /// Yo'naltirishni ko'rib chiqish va qabul qilish/yakunlash
  bool canProcessReferral(UserModel user, ReferralModel referral) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator) {
      return true;
    }
    if (referral.fromSpecialistId == user.id) return true;
    if (referral.toSpecialistId == user.id) return true;
    if (referral.toSpecialistType == user.role.label ||
        referral.toSpecialistType == user.specialization) {
      return true;
    }
    return false;
  }

  // ==================== FOYDALANUVCHILARNI VA TIZIMNI BOSHQARISH ====================
  /// Yangi xodim qo'shish, rol va maktab biriktirish
  bool canManageUsers(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin;
  }

  /// Administrator portaliga to'liq kirish huquqi
  bool canAccessAdminPortal(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin;
  }

  /// Tizim umumiy sozlamalarini boshqarish
  bool canManageSystemSettings(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin;
  }

  /// Rollar va ruxsatlar matritsasini boshqarish
  bool canManageRolesAndPermissions(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin;
  }

  /// Muassasalar reyestri va ma'lumotlarini boshqarish
  bool canManageInstitutions(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin;
  }

  /// Sinflar va guruhlar tarkibini boshqarish
  bool canManageClasses(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator;
  }

  /// Audit jurnalini ko'rish
  bool canViewAuditLogs(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.reviewer;
  }
}
