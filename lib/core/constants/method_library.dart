import '../../models/user_model.dart';
import 'defectology_methods_data.dart';
import 'psychological_methods_data.dart';

/// Barcha mutaxassislik metodikalari: har bir kabinet o'z kutubxonasini ko'radi.
class MethodLibrary {
  static List<PsychologicalMethodItem> get all => [
    ...PsychologicalMethodsData.methods,
    ...DefectologyMethodsData.methods,
  ];

  /// Rolga mos metodikalar. Rahbariyat va tizim administratori barchasini ko'radi.
  static List<PsychologicalMethodItem> forRole(UserRole role) => switch (role) {
    UserRole.psychologist => PsychologicalMethodsData.methods,
    UserRole.specialEducation => DefectologyMethodsData.methods,
    UserRole.superAdmin ||
    UserRole.institutionAdmin ||
    UserRole.coordinator ||
    UserRole.reviewer => all,
    _ => const [],
  };

  static PsychologicalMethodItem? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
