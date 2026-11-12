import 'package:web/web.dart' as web;

/// Sayt bosh ekranga qo'shilib, ilova kabi ochilganmi (iPhone/Android PWA).
/// Shunda u ham ilova kabi kirgan holda qoladi; oddiy brauzer oynasida esa
/// brauzer yopilganda qayta kirish so'raladi.
bool get runsAsInstalledApp {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    if (web.window.matchMedia('(display-mode: fullscreen)').matches) {
      return true;
    }
  } catch (_) {}
  return false;
}
