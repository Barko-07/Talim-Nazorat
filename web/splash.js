// Removes the HTML loading screen once Flutter has drawn its first frame.
// A separate file, not an inline script: the Content-Security-Policy allows
// scripts from this site only.
(function () {
  'use strict';
  function hide() {
    var el = document.getElementById('app-splash');
    if (!el) return;
    el.classList.add('hide');
    setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 400);
  }
  window.addEventListener('flutter-first-frame', hide, { once: true });
  // Safety net: never leave the splash over a running app.
  setTimeout(hide, 30000);
})();
