// The opening animation on the website: hidden once Flutter has drawn its
// first frame AND the animation has played (2.4 s), so it is always seen in
// full and the landing page follows smoothly. A separate file, not an inline
// script: the Content-Security-Policy allows scripts from this site only.
(function () {
  'use strict';
  var started = Date.now();
  var MIN_SHOW = 2400;
  var done = false;
  function hide() {
    if (done) return;
    done = true;
    var el = document.getElementById('app-splash');
    if (!el) return;
    el.classList.add('hide');
    setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 500);
  }
  window.addEventListener('flutter-first-frame', function () {
    var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var wait = reduce ? 0 : Math.max(0, MIN_SHOW - (Date.now() - started));
    setTimeout(hide, wait);
  }, { once: true });
  // Safety net: never leave the splash over a running app.
  setTimeout(hide, 30000);
})();
