// Removes the plain loading background as soon as Flutter has drawn its first
// frame: the opening animation (IntroScreen) starts on the same colour, so the
// hand-over is invisible. A separate file, not an inline script: the
// Content-Security-Policy allows scripts from this site only.
(function () {
  'use strict';
  function hide() {
    var el = document.getElementById('app-splash');
    if (el && el.parentNode) el.parentNode.removeChild(el);
  }
  window.addEventListener('flutter-first-frame', hide, { once: true });
  setTimeout(hide, 30000); // safety net
})();
