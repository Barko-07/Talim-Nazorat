import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/assessment_question_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/referral_model.dart';

/// Rollar bo'yicha ruxsatlar matritsasi (yagona manba).
///
/// Asosiy tamoyillar:
/// - Har bir foydalanuvchi faqat o'z muassasasi bilan ishlaydi (tizim administratoridan tashqari).
/// - Bolalar bilan bevosita ishlaydigan mutaxassislar va o'qituvchilar faqat o'zlariga
///   biriktirilgan bolalarni ko'radi. Koordinator, rahbariyat va kuzatuvchi — butun maktabni.
/// - Bola ma'lumotini o'zgartirish uchun avvalo uni ko'rish huquqi bo'lishi shart.
/// - Bloklangan foydalanuvchi hech narsa qila olmaydi.
class AccessControlService {
  static final AccessControlService _instance =
      AccessControlService._internal();
  factory AccessControlService() => _instance;
  AccessControlService._internal();

  /// Butun maktab bolalarini ko'radigan rollar
  static const schoolWideRoles = {
    UserRole.institutionAdmin,
    UserRole.coordinator,
    UserRole.reviewer,
  };

  /// Bolalar bilan bevosita ishlaydigan va bolalar biriktiriladigan rollar
  static const childFacingRoles = {
    UserRole.psychologist,
    UserRole.speechTherapist,
    UserRole.specialEducation,
    UserRole.specialEdTeacher,
    UserRole.teacher,
  };

  /// Bolaning rivojlanish profilini (imkoniyatlar profili, ishchi sinf) o'zgartiradiganlar.
  /// Keyinchalik ota-onaga ham ruxsat berish shu yerda qo'shiladi.
  static const developmentProfileEditors = {
    UserRole.psychologist,
    UserRole.speechTherapist,
    UserRole.specialEducation,
  };

  /// Fan bo'yicha bilim darajasini baholaydigan va fan topshiriqlarini beradiganlar
  static const subjectLevelAssessors = {
    UserRole.specialEdTeacher,
    UserRole.specialEducation,
    UserRole.teacher,
    UserRole.coordinator,
  };

  /// Bolalarga mutaxassis biriktira oladiganlar
  static const specialistAssigners = {
    UserRole.institutionAdmin,
    UserRole.coordinator,
  };

  // ==================== MAKTAB IZOLYATSIYASI ====================
  /// Foydalanuvchi va yozuv bir xil muassasaga tegishlimi?
  bool isSameInstitution(
    UserModel user,
    String? institutionId,
    String? institutionName,
  ) {
    if (user.role == UserRole.superAdmin) return true;
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

  bool _sameSchool(UserModel user, StudentModel student) =>
      isSameInstitution(user, student.institutionId, student.institutionName);

  // ==================== O'QUVCHINI KO'RISH ====================
  /// O'quvchi ma'lumotlarini ko'rish ruxsati
  bool canViewStudent(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (!_sameSchool(user, student)) return false;
    if (schoolWideRoles.contains(user.role)) return true;
    if (childFacingRoles.contains(user.role)) {
      return isStudentAssignedTo(user, student);
    }
    return false;
  }

  /// O'quvchi shu foydalanuvchiga bevosita biriktirilganmi?
  bool isStudentAssignedTo(UserModel user, StudentModel student) {
    if (student.assignedSpecialistIds.contains(user.id)) return true;
    if (user.assignedStudentIds.contains(student.id)) return true;
    if (student.coordinatorId == user.id) return true;
    return false;
  }

  /// Maxfiy tibbiy yoki psixologik ma'lumotlarni ko'rish (Least-privilege)
  bool canViewSensitiveMedical(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.psychologist ||
        user.role == UserRole.speechTherapist ||
        user.role == UserRole.specialEducation ||
        user.role == UserRole.coordinator;
  }

  /// Maxfiy psixologik kuzatuvni ko'rish: faqat muallif, psixologlar va tizim administratori.
  bool canViewConfidentialObservation(UserModel user, String psychologistId) {
    if (!user.isActive) return false;
    if (user.id == psychologistId) return true;
    return user.role == UserRole.psychologist ||
        user.role == UserRole.superAdmin;
  }

  // ==================== O'QUVCHINI BOSHQARISH ====================
  /// O'quvchi anketasini yaratish ([student] — yangi yoki mavjud) yoki tahrirlash
  bool canEditStudent(UserModel user, StudentModel? student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (user.role != UserRole.institutionAdmin &&
        user.role != UserRole.coordinator) {
      return false;
    }
    return student == null || _sameSchool(user, student);
  }

  /// O'quvchini arxivlash
  bool canArchiveStudent(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return user.role == UserRole.institutionAdmin && _sameSchool(user, student);
  }

  /// Bolaga mutaxassis biriktirish yoki biriktirishni bekor qilish
  bool canAssignSpecialists(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return specialistAssigners.contains(user.role) && _sameSchool(user, student);
  }

  /// [specialist] shu bolaga biriktirilishi mumkinmi (faol, bolalar bilan ishlaydi, shu maktabdan)
  bool canBeAssigned(UserModel specialist, StudentModel student) {
    return specialist.isActive &&
        childFacingRoles.contains(specialist.role) &&
        _sameSchool(specialist, student);
  }

  bool canEditDevelopmentProfile(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return developmentProfileEditors.contains(user.role) &&
        canViewStudent(user, student);
  }

  bool canAssessSubjectLevel(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return subjectLevelAssessors.contains(user.role) &&
        canViewStudent(user, student);
  }

  /// Logopedik tovushlar kartasini yuritish: bolaga biriktirilgan logoped
  bool canTrackSounds(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return user.role == UserRole.speechTherapist && canViewStudent(user, student);
  }

  // ==================== BAHOLASH VA SAVOLLAR ====================
  /// Baholash o'tkazish va natija/o'lchov kiritish
  bool canCreateAssessment(UserModel user, StudentModel student) {
    if (!user.isActive || !user.role.canCreateAssessments) return false;
    if (user.role == UserRole.superAdmin) return true;
    return canViewStudent(user, student);
  }

  /// Baholashni o'zgartirish yoki o'chirish (muallif yoki rahbariyat)
  bool canModifyAssessment(UserModel user, AssessmentModel assessment) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (assessment.specialistId == user.id) return true;
    return user.role == UserRole.institutionAdmin;
  }

  bool canCreateQuestion(UserModel user) =>
      user.isActive && user.role.canCreateAssessments;

  /// Standart savollarni faqat tizim administratori o'zgartiradi; boshqalarini — muallif
  bool canModifyQuestion(UserModel user, AssessmentQuestionModel question) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    if (question.isStandard) return false;
    return question.authorId == user.id;
  }

  /// Psixologik kuzatuv yozish (psixolog kabineti)
  bool canWriteObservation(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    return user.role == UserRole.psychologist && canViewStudent(user, student);
  }

  // ==================== MASHG'ULOTLAR ====================
  bool canScheduleSession(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.reviewer || user.role == UserRole.parent) {
      return false;
    }
    if (user.role == UserRole.superAdmin) return true;
    return canViewStudent(user, student);
  }

  /// Mashg'ulotni yakunlash, holatini o'zgartirish yoki o'chirish (mas'ul mutaxassis yoki rahbariyat)
  bool canCompleteSession(UserModel user, SessionModel session) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin) {
      return true;
    }
    return session.specialistId == user.id;
  }

  // ==================== INDIVIDUAL TA'LIM REJASI ====================
  bool canManageIep(UserModel user, IndividualEducationPlanModel? plan) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin) return true;
    final schoolOk =
        plan == null || isSameInstitution(user, null, plan.institutionName);
    if (user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator ||
        user.role == UserRole.specialEdTeacher) {
      return schoolOk;
    }
    return plan != null && plan.responsibleTeacherId == user.id;
  }

  bool canUpdateObjectiveProgress(
    UserModel user,
    IndividualEducationPlanModel plan,
    PlanObjectiveModel objective,
  ) {
    if (canManageIep(user, plan)) return true;
    if (!user.isActive) return false;
    return objective.responsibleSpecialistId == user.id;
  }

  // ==================== YO'NALTIRISHLAR VA MONITORING ====================
  bool canCreateReferral(UserModel user) {
    if (!user.isActive) return false;
    return user.role != UserRole.reviewer && user.role != UserRole.parent;
  }

  /// Yo'naltirishni ko'rish va holatini o'zgartirish
  bool canProcessReferral(UserModel user, ReferralModel referral) {
    if (!user.isActive) return false;
    if (user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator) {
      return true;
    }
    if (referral.fromSpecialistId == user.id) return true;
    if (referral.toSpecialistId == user.id) return true;
    return referral.toSpecialistType == user.role.label ||
        referral.toSpecialistType == user.specialization;
  }

  /// Monitoring signalini hal qilish
  bool canResolveAlert(UserModel user, StudentModel student) {
    if (!user.isActive) return false;
    if (user.role == UserRole.reviewer || user.role == UserRole.parent) {
      return false;
    }
    return canViewStudent(user, student);
  }

  // ==================== TIZIMNI BOSHQARISH ====================
  bool canManageUsers(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin;
  }

  bool canAccessAdminPortal(UserModel user) =>
      user.isActive && user.role == UserRole.superAdmin;

  bool canManageSystemSettings(UserModel user) =>
      user.isActive && user.role == UserRole.superAdmin;

  bool canManageRolesAndPermissions(UserModel user) =>
      user.isActive && user.role == UserRole.superAdmin;

  bool canManageInstitutions(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin;
  }

  bool canManageClasses(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.coordinator;
  }

  bool canViewAuditLogs(UserModel user) {
    if (!user.isActive) return false;
    return user.role == UserRole.superAdmin ||
        user.role == UserRole.institutionAdmin ||
        user.role == UserRole.reviewer;
  }
}
