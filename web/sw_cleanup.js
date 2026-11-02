// Eski service worker va keshlarni tozalash (yangi versiya har doim yuklansin).
// Inline <script> o'rniga alohida fayl — Content-Security-Policy faqat 'self' skriptlarga ruxsat beradi.
(function () {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (registrations) {
      for (var i = 0; i < registrations.length; i++) {
        registrations[i].unregister();
      }
    });
  }
  if ('caches' in window) {
    caches.keys().then(function (names) {
      for (var i = 0; i < names.length; i++) {
        caches.delete(names[i]);
      }
    });
  }
})();
