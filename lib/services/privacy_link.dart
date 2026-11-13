import 'package:url_launcher/url_launcher.dart';

/// Maxfiylik siyosati sahifasi (saytda ochiq, Play Market ham shu manzilni so'raydi).
final privacyPolicyUri = Uri.parse('https://individ.uz/privacy.html');

/// Brauzerda (yangi oynada) yoki telefonda tashqi brauzerda ochadi.
Future<void> openPrivacyPolicy() async {
  await launchUrl(privacyPolicyUri, mode: LaunchMode.externalApplication);
}
