// Account deletion without the app (Google Play requirement). Uses the same
// API as the app: login (+ emailed code for admins), then delete with password.
(function () {
  'use strict';
  let csrf = '';

  async function api(path, body) {
    const headers = { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' };
    if (csrf) headers['X-CSRF-Token'] = csrf;
    const res = await fetch(path, { method: 'POST', credentials: 'same-origin', headers, body: JSON.stringify(body) });
    let data = {};
    try { data = await res.json(); } catch (_) { /* empty body */ }
    if (data.csrf_token) csrf = data.csrf_token;
    if (!res.ok) throw new Error(data.message || 'Xatolik yuz berdi. Qayta urinib ko‘ring.');
    return data;
  }

  function show(id) {
    for (const el of document.querySelectorAll('main > form, #done')) el.hidden = el.id !== id;
    const first = document.querySelector('#' + id + ' input');
    if (first) first.focus();
  }

  function guard(form, handler) {
    form.addEventListener('submit', async function (e) {
      e.preventDefault();
      const btn = form.querySelector('button');
      const msg = form.querySelector('.msg');
      msg.textContent = ''; msg.className = 'msg';
      btn.disabled = true;
      try { await handler(); } catch (err) { msg.textContent = err.message; msg.className = 'msg err'; }
      finally { btn.disabled = false; }
    });
  }

  function afterLogin(data) {
    if (data.state === 'email_code_required') { show('code'); return; }
    if (data.state !== 'ok') throw new Error('Avval ilovada kirishni yakunlang (parolni yangilash yoki himoyani sozlash).');
    document.getElementById('who').textContent = (data.user && data.user.email ? data.user.email : '') +
      ' hisobi o‘chiriladi.';
    show('confirm');
  }

  guard(document.getElementById('login'), async function () {
    const data = await api('/api/auth/login', {
      email: document.getElementById('email').value.trim().toLowerCase(),
      password: document.getElementById('password').value,
    });
    afterLogin(data);
  });

  guard(document.getElementById('code'), async function () {
    const data = await api('/api/auth/email-code/verify', { code: document.getElementById('otp').value.trim() });
    afterLogin(data);
  });

  guard(document.getElementById('confirm'), async function () {
    await api('/api/auth/account/delete', { password: document.getElementById('password2').value });
    document.getElementById('password').value = '';
    document.getElementById('password2').value = '';
    show('done');
  });
})();
