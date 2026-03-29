/* ============================================================
   Demon of Fire – Portfolio Website
   main.js
   ============================================================ */

(function () {
  'use strict';

  /* ── Hamburger / Nav Toggle ── */
  const toggle = document.getElementById('nav-toggle');
  const navLinks = document.getElementById('nav-links');

  if (toggle && navLinks) {
    toggle.addEventListener('click', function () {
      const isOpen = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!isOpen));
      navLinks.classList.toggle('is-open', !isOpen);
    });

    /* Close menu when a link is clicked (mobile) */
    navLinks.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        toggle.setAttribute('aria-expanded', 'false');
        navLinks.classList.remove('is-open');
      });
    });

    /* Close menu on Escape key */
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && navLinks.classList.contains('is-open')) {
        toggle.setAttribute('aria-expanded', 'false');
        navLinks.classList.remove('is-open');
        toggle.focus();
      }
    });

    /* Close menu when clicking outside the nav */
    document.addEventListener('click', function (e) {
      const nav = document.getElementById('site-nav');
      if (nav && !nav.contains(e.target) && navLinks.classList.contains('is-open')) {
        toggle.setAttribute('aria-expanded', 'false');
        navLinks.classList.remove('is-open');
      }
    });
  }

  /* ── Mark active nav link ── */
  const currentPath = window.location.pathname.replace(/\/$/, '') || '/index.html';
  document.querySelectorAll('.nav-links a').forEach(function (link) {
    const linkPath = new URL(link.href).pathname.replace(/\/$/, '');
    if (linkPath === currentPath) {
      link.setAttribute('aria-current', 'page');
    }
  });

  /* ── Current year in footer ── */
  const yearEl = document.getElementById('current-year');
  if (yearEl) {
    yearEl.textContent = new Date().getFullYear();
  }
})();
